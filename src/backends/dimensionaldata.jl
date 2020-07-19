using DataStructures
using DimensionalData

import Base: getindex, keys, haskey, convert, show, IO, MIME


"""
DimensionalData provides the equivalent of an xarray `DataArray`, this wrapper
adds the functionality of an xarray `DataSet` by containing multiple
`DimensionalArray`s.

Object should be created by calling the relevant
`convert($(FUNCTIONNAME), dataset::DataSet)` method on a [`DataSet`](@ref DataSet).

# See also

[`Backend`](@ref Backend), [`ArrayWrapper`](@ref ArrayWrapper)
"""
struct DimensionalArrayWrapper <: ArrayWrapper
    "Dictionary of `DimensionName::String => DimensionLength::Int`"
    dimensions::OrderedDict
    "Named tuple of `DatasetName::Symbol => Dataset::DimensionalArray`"
    datasets::T where T <: NamedTuple
    "Dictionary of `AttributeName::String => AttributeValue::Any`"
    attributes::OrderedDict
    "Dictionary containing encoding information (usually `source`, `filter_by_keys`, and `ecode_cf`)"
    encoding::Dict

    #  Manually define inner constructor here so that it does not appear twice
    #  in the docs
    DimensionalArrayWrapper(dimensions, datasets, attributes, encoding) = new(dimensions, datasets, attributes, encoding)
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

function Base.convert(
    ::Type{DimensionalArrayWrapper},
    dataset::CfGRIB.DataSet
)::DimensionalArrayWrapper
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

convert(::Type{DimensionalArray}, dataset::DataSet) = convert(DimensionalArrayWrapper, dataset)::DimensionalArrayWrapper
