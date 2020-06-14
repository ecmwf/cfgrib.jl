using FileIO


#  Goal is for the backends to be optional, so only include the files if the
#  user has the required backend installed
BACKEND_LIST = [:AxisArrays]
BACKEND_MAPPING = Dict{Symbol, DataType}()

try
    using AxisArrays
    include("./backends/axisarrays.jl")
    #  Using the `Module` as a key doesn't work for... some reason
    # BACKEND_MAPPING[AxisArrays] = AxisArrayWrapper
    #  Use a symbol instead
    BACKEND_MAPPING[:AxisArrays] = AxisArrayWrapper
catch e
    if !(e isa ArgumentError)
        throw(e)
    end
end

#  If no backends could be loaded print a warning
if length(BACKEND_MAPPING) == 0
    @warn """No backends could be loaded, please include one of: $BACKEND_LIST
    Run `import Pkg; Pkg.add("BACKEND")` to install one of the array backends"""
    default_backend = nothing
else
    #  Set the default to the first available backend
    default_backend = Base.first(BACKEND_MAPPING)[1]
end

#  Fallback to an unwrapped DataSet if there are no available backends (`nothing`)
#  or if the user requests a `DataSet` 'backend'
BACKEND_MAPPING[:nothing] = DataSet
BACKEND_MAPPING[:DataSet] = DataSet

function load(f::String; backend=default_backend, kwargs...)
    ds = DataSet(f, kwargs...)

    backend = Symbol(backend)

    if !(backend in BACKEND_MAPPING)
        throw()
    end

    return convert(BACKEND_MAPPING[backend], ds)
end

function fileio_load(f::File{format"GRIB"}; backend=default_backend, kwargs...)
    """ Load command for FileIO integration. Following line must be in the
    FileIO Registry for this to function properly:

        add_format(format"GRIB", UInt8[0x47, 0x52, 0x49, 0x42], ".grib", [:CfGRIB])
    """
    CfGRIB.load(f.filename; backend=backend, kwargs...)
end
