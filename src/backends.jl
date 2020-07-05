module Backends

using FileIO
using Requires
using CfGRIB

#  Goal is for the backends to be optional, so only include the files if the
#  user has the required backend installed
BACKEND_PROVIDERS = [:AxisArrays, :DimensionalData]
AVAILABLE_BACKENDS = []
DEFAULT_BACKEND = DataSet

function __init__()
    @require AxisArrays = "39de3d68-74b9-583c-8d2d-e117c070f3a9" begin
        include("./backends/dimensionaldata.jl")
        println("Weee")
        global DEFAULT_BACKEND = AxisArrayWrapper
        append!(AVAILABLE_BACKENDS, [:AxisArray])
    end

    @require DimensionalData="0703355e-b756-11e9-17c0-8b28908087d0" begin
        include("./backends/axisarrays.jl")
        println("Weee")
        global DEFAULT_BACKEND = DimensionalArrayWrapper
        append!(AVAILABLE_BACKENDS, [:DimensionalArray])
    end

    if DEFAULT_BACKEND == DataSet
        @warn """No backends could be loaded, setting default to bare `DataSet`.
        Please include one of: $BACKEND_PROVIDERS.
        Run `import Pkg; Pkg.add("BACKEND")` to install one of the array backends"""
    end
end

function fileio_load(f::File{format"GRIB"}; backend=DEFAULT_BACKEND, kwargs...)
    """ Load command for FileIO integration. Following line must be in the
    FileIO Registry for this to function properly:

        add_format(format"GRIB", UInt8[0x47, 0x52, 0x49, 0x42], ".grib", [:CfGRIB])
    """
    ds = DataSet(f.filename, kwargs...)
    return convert(backend, ds)
end

end # module
