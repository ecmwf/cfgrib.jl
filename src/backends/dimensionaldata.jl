using DataStructures
using DimensionalData

import Base: getindex, keys, haskey, convert, show, IO, MIME


struct DimensionalArrayWrapper
    dimensions::OrderedDict
    datasets::T where T <: NamedTuple
    attributes::OrderedDict
    encoding::Dict
end

getindex(obj::DimensionalArrayWrapper, key) = getfield(obj, :datasets)[key]
keys(obj::DimensionalArrayWrapper) = keys(getfield(obj, :datasets))
haskey(obj::DimensionalArrayWrapper, key) = key in keys(obj)

function Base.getproperty(obj::DimensionalArrayWrapper, key::Symbol)
    if key in keys(obj)
        return getindex(obj, key)
    else
        return getfield(obj, key)
    end
end

function Base.convert(::Type{DimensionalArrayWrapper}, dataset::CfGRIB.DataSet)
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
    shared_axis = [Dim{Symbol(k)}(dataset.variables[k].data) for k in keys(dataset.dimensions)]

    datasets = NamedTuple{Tuple(Symbol.(multidimensional_keys))}((
        DimensionalArray(CfGRIB.convert(Array, dataset.variables[k].data), Tuple(shared_axis))
        for k in multidimensional_keys
    ))

    return DimensionalArrayWrapper(dimensions, datasets, attributes, encoding)
end

convert(::Type{DimensionalArray}, dataset::DataSet) = convert(DimensionalArrayWrapper, dataset)
