using FileIO


add_format(format"GRIB", UInt8[0x47, 0x52, 0x49, 0x42], ".grib", [:CfGRIB])

function load(f::File{format"GRIB"}; kwargs...)
    open(f) do s
        ret = load(s)
    end
end
