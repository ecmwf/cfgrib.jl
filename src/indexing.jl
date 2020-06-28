using DataStructures
using GRIB


export FileIndex


"""
    FileIndex

A mutable store for indices of a GRIB file

# Constructors
```julia
FileIndex(grib_path::String, index_keys::Array{String, 1})
```

# Fields
 - `allowed_protocol_version::VersionNumber` : Version number used when saving/hashing index files
 - `grib_path::String` : Path to the file the index belongs to
 - `index_path::String` : Path to the index cache file
 - `index_keys::Array{String, 1}` :
 - `offsets::Array` :
 - `header_values::OrderedDict{String, Array}` :
 - `filter_by_keys::Dict` :
"""
mutable struct FileIndex
    allowed_protocol_version::VersionNumber

    grib_path::String
    index_path::String

    index_keys::Array{String, 1}
    offsets::Array  # TODO: Specify offset type better
    message_lengths::Array{Int, 1}
    header_values::OrderedDict{String, Array}

    filter_by_keys::Dict

    FileIndex() = new(v"0.0.0")
end

function FileIndex(grib_path::String, index_keys::Array{String, 1})
    fileindex = FileIndex()
    fileindex.grib_path = grib_path
    fileindex.index_keys = index_keys

    if isfile(index_path(fileindex))
        from_indexfile!(fileindex)
    else
        from_gribfile!(fileindex)
        get_header_values!(fileindex)
    end

    return fileindex
end

Base.getindex(obj::FileIndex, key) = obj.header_values[key]


function index_path(index::FileIndex)
    index_keys_hash = hash(
        join([index.index_keys..., index.allowed_protocol_version])
    )
    index_keys_hash = string(index_keys_hash, base=16)

    return "$(index.grib_path).$index_keys_hash.idx"
end

index_path!(index::FileIndex) = setfield!(index, :index_path, index_path(index))


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
        message_lengths = Array{Int, 1}(undef, f.nmessages)
        for (nmessage, message) in enumerate(f)
            header_values = Array{Any}(undef, index_key_count)
            for (i, key) in enumerate(index_keys)
                value = read_message(message, key)

                # #  Useful for debugging
                # value_naive = haskey(message, key) ? message[key] : missing
                # value_naive = value_naive isa Array ? Tuple(value_naive) : value_naive
                # value_naive = key == "time" ? from_grib_date_time(message) : value_naive
                # if any(ismissing.([value_naive, value]))
                #     if !all(ismissing.([value_naive, value]))
                #         println("$key: $value vs $value_naive")
                #     end
                # elseif value_naive != value
                #     println("$key: $value vs $value_naive")
                # end

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

            message_lengths[nmessage] = Int(message["totalLength"])
            offsets[HeaderTuple(header_values)] = offset_field
        end
        index.message_lengths = message_lengths
    end

    index.offsets = collect(pairs(offsets))
end


function get_header_values!(index::FileIndex)
    header_values = OrderedDict{String, Array}()
    for key in index.index_keys
        header_values[key] = unique([
            offset[1][Symbol(key)]
            for offset
            in index.offsets
        ])
    end

    index.header_values = header_values
end


function getone(index::FileIndex, item)
    values = index[item]

    if length(values) != 1
        throw("Expected 1 value for $(item), found $(length(values)) instead")
    end

    return values[1]
end


function first(index::FileIndex)
    GribFile(index.grib_path) do file
        first_offset = index.offsets[1][2][1]
        #  There is a discrepancy between how offsets are defined and used
        #  in cfgrib with the GRIB file seek method and in the Julia GRIB
        #  package, in Julia seek seeks through the messages themselves not
        #  the actual offset values. Here we use the cumulative sum of the
        #  message lengths to work out which message an offset value is in.
        message_length_cumsum = cumsum(index.message_lengths)
        offset_message_index = findfirst(message_length_cumsum .> first_offset) - 1
        seek(file, offset_message_index)
        return Message(file)
    end
end


function filter_offsets(index::FileIndex; query...)
    filtered_offsets = Array{Pair{Any,Any},1}()

    for (header_values, offset_values) in index.offsets
        for (k, v) in query
            if ismissing(header_values[k]) && ismissing(v)
                append!(filtered_offsets, [Pair(header_values, offset_values)])
            elseif ismissing(header_values[k]) || header_values[k] != v
                break
            else
                append!(filtered_offsets, [Pair(header_values, offset_values)])
            end
        end
    end

    return filtered_offsets
end

function filter(index::FileIndex; query...)::FileIndex
    filtered_offsets = filter_offsets(index; query...)

    filtered_index = deepcopy(index)
    filtered_index.offsets = filtered_offsets
    filtered_index.filter_by_keys = query

    get_header_values!(filtered_index)

    return filtered_index
end

function filter!(index::FileIndex; query...)
    filtered_offsets = filter_offsets(index; query...)

    index.offsets = filtered_offsets
    index.filter_by_keys = query

    get_header_values!(index)
end
