using DataStructures
using AxisArrays

import Base: getindex, keys, convert, show, IO, MIME


struct AxisArrayWrapper
    dimensions::OrderedDict
    datasets::T where T <: NamedTuple
    attributes::OrderedDict
    encoding::Dict
end

getindex(obj::AxisArrayWrapper, key) = getfield(obj, :datasets)[key]
keys(obj::AxisArrayWrapper) = keys(getfield(obj, :datasets))
haskey(obj::AxisArrayWrapper, key) = key in keys(obj)

function Base.getproperty(obj::AxisArrayWrapper, key::Symbol)
    if key in keys(obj)
        return getindex(obj, key)
    else
        return getfield(obj, key)
    end
end

function convert(::Type{AxisArrayWrapper}, dataset::DataSet)
    dimensions = dataset.dimensions
    attributes = dataset.attributes
    encoding = dataset.encoding

    multidimensional_idx =  (
        [size(v.data) for v in values(dataset.variables)]
        .|> length
        .|> x -> x > 1)
    multidimensional_keys = collect(keys(dataset.variables))[multidimensional_idx]
    multidimensional_values = [dataset.variables[k] for k in multidimensional_keys]

    shared_dimensions = [dataset.variables[k] for k in keys(dataset.dimensions)]
    shared_axis = [Axis{Symbol(k)}(dataset.variables[k].data) for k in keys(dataset.dimensions)]

    datasets = NamedTuple{Tuple(Symbol.(multidimensional_keys))}((
        AxisArray(CfGRIB.convert(Array, dataset.variables[k].data), shared_axis...)
        for k in multidimensional_keys
    ))

    return AxisArrayWrapper(dimensions, datasets, attributes, encoding)
end

convert(::Type{AxisArray}, dataset::DataSet) = convert(AxisArrayWrapper, dataset)

function Base.show(io::IO, mime::MIME"text/plain", da::CfGRIB.AxisArrayWrapper)
    dimensions_list = join(["$k: $v" for (k,v) in pairs(da.dimensions)], ", ")
    str_dimensions = " Dimensions ($(length(da.dimensions))):\n  $dimensions_list"

    dataset_list = [summary(ds) for ds in da.datasets]
    axes_list = split(dataset_list[1], "\n")[2:end-1]
    axes_list = replace.(axes_list, "    "=>"  ")
    #  When arrays are printed their length is limited by the current displaysize
    #  so adding text befor/after will make the text overflow to the next line
    #  here we do a hacky fix for that
    display_width = displaysize(io)[2]
    for (i, line) in enumerate(axes_list)
        if length(line) <= display_width
            continue
        end

        new_line = split(line, ",")

        #  dot dot dot (…) index - index of pair of values that has elipses
        #  e.g. `15.0 … 342.0`
        ddd_idx = findfirst(occursin.("…", split(line, ",")))
        while sum(length.(new_line))+length(new_line)+3 > display_width
            deleteat!(new_line, ddd_idx)
            str_new_elipses = "$(new_line[ddd_idx-1])  … $(new_line[ddd_idx])"
            deleteat!(new_line, ddd_idx-1)
            new_line[ddd_idx-1] = str_new_elipses
            ddd_idx = ddd_idx - 1
        end

        axes_list[i] = join(new_line, ",")
    end

    axes_list = join(axes_list, "\n")
    str_axes = " Axes: \n$axes_list"

    dataset_data = [split(dl, "\n")[end] for dl in dataset_list]
    dataset_data = [
        "   "*replace(s, "And data, a"=>string(keys(da.datasets)[i])*",")
        for (i, s)
        in enumerate(dataset_data)
    ]
    dataset_variables = join(dataset_data, "\n")

    str_variables = " Variables:\n$dataset_variables"

    str_show = join([str_dimensions, str_axes, str_variables], "\n")

    println(io, "AxisArrayWrapper with $(length(da.datasets)) dataset(s)")

    println(str_show)
    print(" Attributes: ")
    show(io, mime, da.attributes)
end
