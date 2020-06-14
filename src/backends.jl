using FileIO


add_format(format"GRIB", UInt8[0x47, 0x52, 0x49, 0x42], ".grib", [:CfGRIB])


#  Goal is for the backends to be optional, so only include the files if the
#  user has the required backend installed
BACKEND_MAPPING = Dict{Symbol, DataType}()

try
    using AxisArrays
    include("./backends/axisarrays.jl")
    #  Doesn't work for... some reason
    # BACKEND_MAPPING[AxisArrays] = AxisArrayWrapper
    BACKEND_MAPPING[:AxisArrays] = AxisArrayWrapper
catch e
    if !(e isa ArgumentError)
        throw(e)
    end
end

default_backend = Base.first(BACKEND_MAPPING)[1]

function load(f::File{format"GRIB"}; backend=default_backend, kwargs...)
    ds = DataSet(f.filename, kwargs...)

    backend = Symbol(backend)

    return convert(BACKEND_MAPPING[backend], ds)
end

