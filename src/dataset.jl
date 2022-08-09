using Base.Iterators
using DataStructures
using Dates
using JSON


export DataSet


struct DatasetBuildError <: Exception
    error_message::String
end


"Struct that contains metadata for an array, used to lazy-load the array from disk only when requested"
struct OnDiskArray{T, N} <: DiskArrays.AbstractDiskArray{T, N}
    grib_path::String
    size::NTuple{N, Int}
    offsets::OrderedDict
    message_lengths::Array{Int,1}
    missing_value::Any
    geo_ndim::Int

    #  Manually define inner constructor here so that it does not appear twice
    #  in the docs
    # OnDiskArray(grib_path, size, offsets, message_lengths, missing_value, geo_ndim, dtype) =
        # new(grib_path, size, offsets, message_lengths, missing_value, geo_ndim, dtype)
end
OnDiskArray(grib_path, size::NTuple{N, Int}, offsets, message_lengths, missing_value, geo_ndim) where N = 
    OnDiskArray{Union{Missing, Float32}, N}(grib_path, size, offsets, message_lengths, missing_value, geo_ndim) 

expand_key(key, shape) = Tuple((1:l)[k] for (k, l) in zip(key, shape))

Base.size(A::OnDiskArray) = A.size

Base.axes(A::OnDiskArray) = Tuple(Base.OneTo(i) for i in size(A))
Base.axes(A::OnDiskArray, d::Int) = axes(A)[d]

DA.eachchunk(A::OnDiskArray) = DA.GridChunks(A, size(A))
DA.haschunks(A::OnDiskArray) = DA.Unchunked()

function Base.convert(::Type{T}, A::OnDiskArray)::T where {T <: Array}
    res = A[repeat([Colon()], length(size(A)))...]
    return T(res)
end

function DA.readblock!(A::OnDiskArray, aout, i::AbstractUnitRange...) where {T,N}
    ndims(A) == length(i) || error("Number of indices is not correct")
    all(r->isa(r,AbstractUnitRange),i) || error("Not all indices are unit ranges")
    # expanded_keys = expand_key(i, size(A))
    #  Geography dims (e.g. lat, lon) are on the end and need to be loaded fully
    #  so only look at the other dimensions
    ngeo = A.geo_ndim
    header_items = i[1:end-ngeo]
    # array_field_shape = (
    #     (length(l) for l in header_items)..., size(A)[end-A.geo_ndim+1:end]...
    # )
    geo_items = i[end-ngeo+1:end]
    # array_field = Array{Union{Missing,T}}(undef, i...)

    geo_ndim_idx = repeat([Colon()], A.geo_ndim)

    GribFile(A.grib_path) do file
        message_length_cumsum = cumsum(A.message_lengths)
        for (header_indexes, offset) in pairs(A.offsets)
            if length(header_indexes) == 0
                array_field_indexes = ()
            else
                array_field_indexes = collect(flatten([
                    findall(it .== ix)
                    for (it, ix)
                    in zip(header_items, header_indexes)
                ]))
            end

            if length(array_field_indexes) != length(header_indexes)
                #  If the index (e.g. [10, 4, 1]) is not in the requested header
                #  range (e.g [1:10, 1:4, 2]) then findall will return fewer
                #  items than required (e.g 2 instead of 3). Skip these cases
                continue
            end

            offset_message_index = findfirst(message_length_cumsum .> offset) - 1
            seek(file, offset_message_index)
            message = Message(file)
            values = message["values"]
            aout[array_field_indexes..., geo_ndim_idx...] = replace(values[geo_items...], A.missing_value => missing)
        end
    end
end

"Struct describing a cfgrib variable"
Base.@kwdef struct Variable
    "Name of the dimension(s) contained in this variable"
    dimensions::Tuple{Vararg{String}}

    "Data contained in the variable, can point ot in-memory data or to a CfGRIB [`OnDiskArray`](@ref OnDiskArray)"
    data::Union{Number,Array,OnDiskArray}

    "Dictionary containing metadata for the variable, typically the units, the long name, and the standard name"
    attributes::Dict{String,Any}

    #  Manually define inner constructor here so that it does not appear twice
    #  in the docs
    Variable(dimensions, data, attributes) = new(dimensions, data, attributes)
end

function Base.:(==)(a::Variable, b::Variable)
    attributes = a.attributes == b.attributes
    dimensions = a.dimensions == b.dimensions
    data = a.data == b.data

    return attributes && dimensions && data
end


"Maps a GRIB file to the NetCDF Common Data Model with CF Conventions."
struct DataSet
    "`OrderedDict{String,Int}` of `\$DIMENSION_NAME => \$DIMENSION_LENGTH`."
    dimensions::OrderedDict{String,Int}

    "`OrderedDict{String,CfGRIB.Variable}` of `\$DIMENSION_NAME => \$DIMENSION_VARIABLE`, where the the variable is a [`Variable`](@ref Variable)."
    variables::OrderedDict{String,CfGRIB.Variable}

    "`OrderedDict{String,Any}` containing some metadata extracted from the file."
    attributes::OrderedDict{String,Any}

    "`Dict{String,Any}` containing metadata related to CfGRIB.jl, e.g. `filter_by_keys`"
    encoding::Dict{String,Any}

    #  Manually define inner constructor here so that it does not appear twice
    #  in the docs
    DataSet(dimensions, variables, attributes, encoding) =
        new(dimensions, variables, attributes, encoding)
end

#  TODO: missing arguments:
#    - grib_errors
#    - index_path
#    -
function DataSet(
    path::String;
    encode_cf::Tuple{Vararg{String}}=("parameter", "time", "geography", "vertical"),
    errors="warn",
    filter_by_keys::Dict=Dict(),
    read_keys::Array{String,1}=String[],
    squeeze::Bool=true,
    time_dims::Tuple{Vararg{String}}=("time", "step"),
)::DataSet
    index_keys = sort([ALL_KEYS..., read_keys...])
    index = FileIndex(path, index_keys) # filter_by_keys=filter_by_keys

    return DataSet(build_dataset_components(
        index;
        errors=errors,
        encode_cf=encode_cf,
        squeeze=squeeze,
        read_keys=read_keys,
        time_dims=time_dims,
    )...)
end


#  TODO: Implement filter_by_keys
function enforce_unique_attributes(
    header_values::OrderedDict{String,T} where {T <: Array},
    attribute_keys::Array,
)
    attributes = OrderedDict()
    for key in attribute_keys
        values = header_values[key]

        if length(values) > 1
            throw(DatasetBuildError(
                "Attributes are not unique for " *
                "$key: $(values)"
            ))
        end

        value = values[1]

        if !ismissing(value) && !(value in ["undef", "unknown"])
            attributes["GRIB_" * key] = value
        end
    end

    return attributes
end


#  TODO: Implement filter_by_keys
function enforce_unique_attributes(index::FileIndex, attribute_keys::Array)
    attributes = enforce_unique_attributes(
        index.header_values, attribute_keys
    )

    return attributes
end


function build_geography_coordinates(
    index::FileIndex,
    encode_cf::Tuple,
    errors
)
    first_message = first(index)
    geo_coord_vars = OrderedDict()
    grid_type = CfGRIB.getone(index, "gridType")

    if "geography" in encode_cf && grid_type in GRID_TYPES_DIMENSION_COORDS
        column_major = getone(index, "jPointsAreConsecutive") != 0
        #  column/row major has always confused me, not sure if this
        #  is the correct approach here. Idea is taken from how GRIB.jl
        #  handles reading data with `codes_grib_get_data`:
        #  https://github.com/weech/GRIB.jl/blob/5710a1f462e888ad38f6e3b282df3fb953478d1b/src/message.jl#L355
        if column_major
            geo_dims = ("latitude", "longitude")
            geo_shape = (getone(index, "Ny"), getone(index, "Nx"))
        else
            geo_dims = ("longitude", "latitude")
            geo_shape = (getone(index, "Nx"), getone(index, "Ny"))
        end
        latitudes = first_message["distinctLatitudes"]
        geo_coord_vars["latitude"] = Variable(
            dimensions=("latitude",),
            data=latitudes,
            attributes=CfGRIB.COORD_ATTRS["latitude"],
        )

        if latitudes[1] > latitudes[end]
            geo_coord_vars["latitude"].attributes["stored_direction"] = "decreasing"
        end

        geo_coord_vars["longitude"] = Variable(
            dimensions=("longitude",),
            data=first_message["distinctLongitudes"],
            attributes=CfGRIB.COORD_ATTRS["longitude"],
        )
    elseif "geography" in encode_cf && grid_type in GRID_TYPES_2D_NON_DIMENSION_COORDS
        column_major = getone(index, "jPointsAreConsecutive") != 0
        if column_major
            geo_dims = ("y", "x")
            geo_shape = (getone(index, "Ny"), getone(index, "Nx"))
        else
            geo_dims = ("x", "y")
            geo_shape = (getone(index, "Nx"), getone(index, "Ny"))
        end
        try
            geo_coord_vars["latitude"] = Variable(
                dimensions=geo_dims,
                data=reshape(first_message["latitudes"], geo_shape),
                attributes=COORD_ATTRS["latitude"],
            )
            geo_coord_vars["longitude"] = Variable(
                dimensions=geo_dims,
                data=reshape(first_message["longitudes"], geo_shape),
                attributes=COORD_ATTRS["longitude"],
            )
        catch e
            rethrow(e)
        end
    else
        geo_dims = ("values",)
        geo_shape = (getone(index, "numberOfPoints"),)
        try
            latitude = first_message["latitudes"]
            geo_coord_vars["latitude"] = Variable(
                dimensions=("values",),
                data=latitude,
                attributes=COORD_ATTRS["latitude"],
            )

            longitude = first_message["longitudes"]
            geo_coord_vars["longitude"] = Variable(
                dimensions=("values",),
                data=longitude,
                attributes=COORD_ATTRS["longitude"],
            )
        catch e
            rethrow(e)
        end
    end

    return geo_dims, geo_shape, geo_coord_vars
end


function encode_cf_first(
    data_var_attrs::OrderedDict,
    encode_cf::Tuple{Vararg{String}}=("parameter", "time"),
    time_dims::Tuple{Vararg{String}}=("time", "step"),
)::Array{String,1}
    #  NOTE: marking value as `const` just means it cannot be reassigned, the
    #  value can still be mutated/appended to, so be careful `append!`ing to
    #  the constants
    coords_map = deepcopy(CfGRIB.ENSEMBLE_KEYS)
    param_id = get(data_var_attrs, "GRIB_paramId", missing)
    data_var_attrs["long_name"] = "original GRIB paramId: $(param_id)"
    data_var_attrs["units"] = "1"

    if "parameter" in encode_cf
        if haskey(data_var_attrs, "GRIB_cfName")
            data_var_attrs["standard_name"] = data_var_attrs["GRIB_cfName"]
        end

        if haskey(data_var_attrs, "GRIB_name")
            data_var_attrs["long_name"] = data_var_attrs["GRIB_name"]
        end

        if haskey(data_var_attrs, "GRIB_units")
            data_var_attrs["units"] = data_var_attrs["GRIB_units"]
        end
    end

    if "time" in encode_cf
        if issubset(time_dims, CfGRIB.ALL_REF_TIME_KEYS)
            append!(coords_map, time_dims)
        else
            throw(
                "time_dims $(time_dims) is not a subset of " *
                "$(CfGRIB.ALL_REF_TIME_KEYS)",
            )
        end
    else
        append!(coords_map, CfGRIB.DATA_TIME_KEYS)
    end

    append!(coords_map, CfGRIB.VERTICAL_KEYS)
    append!(coords_map, CfGRIB.SPECTRA_KEYS)

    return coords_map
end


#  TODO: Add filter_by_keys
function build_variable_components(
    index::FileIndex;
    encode_cf::Tuple{Vararg{String}}=(),
    errors="warn",
    squeeze::Bool=true,
    read_keys::Array{String,1}=String[],
    time_dims::Tuple{Vararg{String}}=("time", "step"),
)
    data_var_attrs_keys = CfGRIB.DATA_ATTRIBUTES_KEYS
    data_var_attrs_keys = [
        data_var_attrs_keys;
        get(CfGRIB.GRID_TYPE_MAP, index["gridType"][1], [])
    ]
    data_var_attrs_keys = [data_var_attrs_keys; read_keys]

    data_var_attrs = enforce_unique_attributes(index, data_var_attrs_keys)

    coords_map = encode_cf_first(data_var_attrs, encode_cf, time_dims)

    coord_name_key_map = Dict()
    coord_vars = OrderedDict()

    for coord_key in coords_map
        values = index[coord_key]
        if length(values) == 1 && ismissing(values[1])
            #  TODO: Add logging
            @warn "Missing from GRIB Stream $(coord_key)"
            continue
        end

        coord_name = coord_key

        if (
            "vertical" in encode_cf &&
            coord_key == "level" &&
            haskey(data_var_attrs, "GRIB_typeOfLevel")
        )
            coord_name = data_var_attrs["GRIB_typeOfLevel"]
            coord_name_key_map[coord_name] = coord_key
        end

        attributes = Dict(
            "long_name" =>
                "original GRIB coordinate for key: $(coord_key)($(coord_name))",
            "units" => "1",
        )

        merge!(attributes, copy(get(CfGRIB.COORD_ATTRS, coord_name, Dict())))

        data = sort(
            values,
            rev=get(attributes, "stored_direction", "none") == "decreasing"
        )
        dimensions = (coord_name,)

        if squeeze && length(values) == 1
            data = data[1]
            #  Should single values be in an array as well?
            # typeof(data) == Array ? nothing : data = [data]
            dimensions = ()
        end

        coord_vars[coord_name] = Variable(dimensions, data, attributes)
    end

    header_dimensions = Tuple(
        d for (d, c)
        in pairs(coord_vars)
        if !squeeze || length(c.data) > 1
    )
    #  Loses information on which shape belongs to which dimension
    #  doesn't seem to matter though
    header_shape = Iterators.flatten(
        Tuple(size(coord_vars[d].data) for d in header_dimensions)
    )

    geo_dims, geo_shape, geo_coord_vars = build_geography_coordinates(
        index, encode_cf, errors
    )

    dimensions = (header_dimensions..., geo_dims...)
    shape = (header_shape..., geo_shape...)

    merge!(coord_vars, geo_coord_vars)

    offsets = OrderedDict{NTuple{length(header_dimensions),Int64},Int}()
    for (header_values, offset) in index.offsets
        header_indexes = Array{Int}(undef, length(header_dimensions))
        for (i, dim) in enumerate(header_dimensions)
            coord_name = get(coord_name_key_map, dim, dim)
            coord_idx = findfirst(index.index_keys .== coord_name)
            header_value = header_values[coord_idx]
            header_indexes[i] = findfirst(coord_vars[dim].data .== header_value)
        end

        offsets[Tuple(header_indexes)] = offset
    end

    missing_value = get(data_var_attrs, "missingValue", 9999)
    data = OnDiskArray{Union{Missing, Float32}, length(shape)}(
        index.grib_path,
        shape,
        offsets,
        index.message_lengths,
        missing_value,
        length(geo_dims),
    )

    if haskey(coord_vars, "time") && haskey(coord_vars, "step")
        # add the 'valid_time' secondary coordinate
        dims, time_data = build_valid_time(
            coord_vars["time"].data,
            coord_vars["step"].data
        )
        attrs = CfGRIB.COORD_ATTRS["valid_time"]
        coord_vars["valid_time"] = Variable(dims, time_data, attrs)
    end

    data_var_attrs["coordinates"] = join(keys(coord_vars), " ")
    data_var = Variable(dimensions, data, data_var_attrs)
    dims = OrderedDict(
        (d => s)
        for (d, s)
        in zip(dimensions, size(data_var.data))
    )

    return dims, data_var, coord_vars
end


#  TODO: logging, filter_by_keys
function build_dataset_attributes(
    index::FileIndex,
    encoding::Dict{String,Any}
)
    attributes = enforce_unique_attributes(index, GLOBAL_ATTRIBUTES_KEYS)
    attributes["Conventions"] = "CF-1.7"

    if "GRIB_centreDescription" in keys(attributes)
        attributes["institution"] = attributes["GRIB_centreDescription"]
    end

    attributes_namespace = Dict(
        "cfgrib_version" => cfgrib_jl_version,  # TODO: Package versions are experimental, this should be changed: https://julialang.github.io/Pkg.jl/dev/api/#Pkg.dependencies
        "cfgrib_open_kwargs" => JSON.json(encoding),
        "eccodes_version" => "missing",  # TODO: Not sure how to get this
        "timestamp" => string(Dates.now()),
    )

    history_in = (
        "timestamp GRIB to CDM+CF via " *
        "cfgrib-cfgrib_version/ecCodes-eccodes_version with cfgrib_open_kwargs"
    )

    [history_in = replace(history_in, p) for p in attributes_namespace]
    #  TODO: Fix quotes, should probably still be double quotes not single
    history_in = replace(history_in, "\"" => "'")
    attributes["history"] = history_in

    return attributes
end


# TODO: Add filter_by_keys
function build_dataset_components(
    index::FileIndex;
    errors="warn",
    encode_cf::Tuple{Vararg{String}}=("parameter", "time", "geography", "vertical"),
    squeeze::Bool=true,
    read_keys::Array{String,1}=String[],
    time_dims::Tuple{Vararg{String}}=("time", "step"),
)
    dimensions = OrderedDict()
    variables = OrderedDict()
    for param_id in index["paramId"]
        var_index = filter(index, paramId=param_id)
        dims, data_var, coord_vars = build_variable_components(
            var_index;
            encode_cf=encode_cf,
            errors=errors,
            squeeze=squeeze,
            read_keys=read_keys,
            time_dims=time_dims,
        )

        short_name = get(data_var.attributes, "GRIB_shortName", "paramId$(param_id)")
        var_name = get(data_var.attributes, "GRIB_cfVarName", "unknown")

        if ("parameter" in encode_cf) && !(var_name == "unknown") && !ismissing(var_name)
            short_name = var_name
        end

        merge!(variables, coord_vars)
        merge!(variables, Dict(short_name => data_var))
        merge!(dimensions, dims)
    end

    encoding = Dict(
        "source" => index.grib_path,
        "filter_by_keys" => "not_implemented",  # TODO: Add filter_by_keys
        "encode_cf" => encode_cf,
    )

    attributes = build_dataset_attributes(index, encoding)

    return dimensions, variables, attributes, encoding
end
