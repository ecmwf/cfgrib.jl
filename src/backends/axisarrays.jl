using AxisArrays

using DataStructures

mutable struct AxisArrayWrapper
    dimensions::OrderedDict
    datasets::T where T <: NamedTuple
    attributes::OrderedDict
    encoding::Dict

    AxisArrayWrapper() = new()
end

Base.getindex(obj::AxisArrayWrapper, key) = obj.datasets[key]
Base.keys(obj::AxisArrayWrapper) = keys(obj.datasets)

function convert(::Type{AxisArrayWrapper}, dataset::DataSet)
    res = AxisArrayWrapper()
    res.dimensions = dataset.dimensions
    res.attributes = dataset.attributes
    res.encoding = dataset.encoding

    multidimensional_idx =  (
        [size(v.data) for v in values(dataset.variables)]
        .|> length
        .|> x -> x > 1)
    multidimensional_keys = collect(keys(dataset.variables))[multidimensional_idx]
    multidimensional_values = [dataset.variables[k] for k in multidimensional_keys]

    shared_dimensions = [dataset.variables[k] for k in keys(dataset.dimensions)]
    shared_axis = [Axis{Symbol(k)}(dataset.variables[k].data) for k in keys(dataset.dimensions)]

    res.datasets = NamedTuple{Tuple(Symbol.(multidimensional_keys))}((
        AxisArray(cfgrib.convert(Array, dataset.variables[k].data), shared_axis...)
        for k in multidimensional_keys
    ))

    return res
end
