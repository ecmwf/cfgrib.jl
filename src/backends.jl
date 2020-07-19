using FileIO
using CfGRIB


#  Goal is for the backends to be optional, so only include the files if the
#  user has the required backend installed
BACKEND_PROVIDERS = [:AxisArrays, :DimensionalData]
AVAILABLE_BACKENDS = []
DEFAULT_BACKEND = DataSet

"""
Backends are wrappers around named array data types, contain information on the
dimensions, attributes, and encoding of the data, as well as the datasets
themselves.

# See also

[`AxisArrayWrapper`](@ref AxisArrayWrapper),
[`DimensionalArrayWrapper`](@ref DimensionalArrayWrapper)
"""
abstract type Backend end

"""
Abstract type for backends which also wrap data types provided by external
packages, instead of just providing a 'vanilla' implementation of the data type.

Python's `xarray` has two fundamental data structures, a `DataArray` which holds
the data for a **single** multi-dimensional variable and its coordinates, as
well as a `Dataset` which holds **multiple DataArrays** that (typically) share
the same coordinates.

# See also

[`AxisArrayWrapper`](@ref AxisArrayWrapper),
[`DimensionalArrayWrapper`](@ref DimensionalArrayWrapper)
"""
abstract type ArrayWrapper <: Backend end

try
    using DimensionalData
    include("./backends/dimensionaldata.jl")
    global DEFAULT_BACKEND = DimensionalArrayWrapper
    append!(AVAILABLE_BACKENDS, [:DimensionalArray])
catch e
    if !(e isa ArgumentError)
        throw(e)
    end
end

try
    using AxisArrays
    include("./backends/axisarrays.jl")
    global DEFAULT_BACKEND = AxisArrayWrapper
    append!(AVAILABLE_BACKENDS, [:AxisArray])
catch e
    if !(e isa ArgumentError)
        throw(e)
    end
end#

#  If no backends could be loaded print a warning
if DEFAULT_BACKEND == DataSet
    @warn """No backends could be loaded, setting default to bare `DataSet`.
    Please include one of: $BACKEND_PROVIDERS.
    Run `import Pkg; Pkg.add("BACKEND")` to install one of the array backends"""
end


# function load(f::String; backend=DEFAULT_BACKEND, kwargs...)
#     ds = DataSet(f, kwargs...)

#     return convert(backend, ds)
# end

function fileio_load(f::File{format"GRIB"}; backend=DEFAULT_BACKEND, kwargs...)
    """ Load command for FileIO integration. Following line must be in the
    FileIO Registry for this to function properly:

        add_format(format"GRIB", UInt8[0x47, 0x52, 0x49, 0x42], ".grib", [:CfGRIB])
    """
    ds = DataSet(f.filename, kwargs...)
    return convert(backend, ds)
end
