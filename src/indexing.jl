using DataStructures
using GRIB


mutable struct FileIndex
    allowed_protocol_version::VersionNumber

    grib_path::String
    index_path::String

    index_keys::Array{String, 1}
    offsets::Array
    header_values::OrderedDict{String, Array}

    filter_by_keys::Dict

    FileIndex() = new(v"0.0.0")
end

function FileIndex(grib_path::String, index_keys::Array{String, 1})
    fileindex = FileIndex()
    fileindex.grib_path = grib_path
    fileindex.index_keys = index_keys

    index_path!(fileindex)

    if isfile(fileindex.index_path)
        from_indexfile!(fileindex)
    else
        from_gribfile!(fileindex)
        get_header_values!(fileindex)
    end

    return fileindex
end

function index_path!(index::FileIndex)
    index_keys_hash = hash(
        join([index.index_keys..., index.allowed_protocol_version])
    )
    index_keys_hash = string(index_keys_hash, base=16)
    index.index_path = ".$(index.grib_path).$index_keys_hash.idx"
end

function save_indexfile(index::FileIndex)
    throw("unimplemented")
end

function from_indexfile!(index::FileIndex)
    throw("unimplemented")
end

function from_gribfile!(index::FileIndex)
    offsets = OrderedDict()
    count_offsets = Dict{Int, Int}()

    index_keys = index.index_keys
    index_key_count = length(index_keys)
    index_key_symbols = Tuple(Symbol.(index_keys))
    HeaderTuple = NamedTuple{index_key_symbols}

    #  TODO: Time function to see if it is worth optimising
    #  based on gribfile.nmessages w/ known-length arrays
    #  more, or if I/O overhead too large
    GribFile(index.grib_path) do f
        for message in f
            header_values = Array{Any}(undef, index_key_count)
            for (i, key) in enumerate(index_keys)
                value = haskey(message, key) ? message[key] : missing
                value = value isa Array ? Tuple(value) : value

                header_values[i] = value
            end

            offset = Int(message["offset"])
            if offset in keys(count_offsets)
                count_offsets[offset] += 1
                offset_field = (offset, count_offsets[offset])
            else
                count_offsets[offset] = 0
                offset_field = offset
            end

            offsets[HeaderTuple(header_values)] = offset_field
        end
    end

    index.offsets = collect(pairs(offsets))
end

function get_header_values!(index::FileIndex)
    header_values = OrderedDict{String, Array}()
    for key in index.index_keys
        header_values[key] = unique([offset[1][Symbol(key)] for offset in index.offsets])
    end

    index.header_values = header_values
end

#  TODO: Implement subindex/filtering
function filter()
    throw("unimplemented")
end
