using DataStructures


struct DatasetBuildError <: Exception
    error_message::String
end


#  TODO: build_array && getindex
struct OnDiskArray
    grib_path::String
    size::Tuple
    offsets::OrderedDict
    missing_value::Any
    geo_ndim::Int
    dtype::Type
end

Base.size(a::OnDiskArray) = a.size


#  TODO: Use parametric struct instead of any
struct Variable
    dimensions::Tuple{Vararg{String}}
    data::Union{Array, OnDiskArray}
    attributes::Dict{String, Any}
end

function Base.:(==)(a::Variable, b::Variable)
    attributes = a.attributes == b.attributes
    dimensions = a.dimensions == b.dimensions
    data = a.data == b.data

    return attributes && dimensions && data
end


function build_geography_coordinates(
        index, encode_cf, errors, log=LOG
    )

    first_message = first(index)
    geo_coord_vars = OrderedDict()
    grid_type = cfgrib.getone(index, "gridType")

    if "geography" in encode_cf && grid_type in GRID_TYPES_DIMENSION_COORDS
        geo_dims = ("latitude", "longitude")
        geo_shape = (getone(index, "Ny"), getone(index, "Nx"))
        latitudes = first_message["distinctLatitudes"]
        geo_coord_vars["latitude"] = Variable(
            ("latitude",), latitudes, cfgrib.COORD_ATTRS["latitude"]
        )

        if latitudes[1] > latitudes[end]
            geo_coord_vars["latitude"].attributes["stored_direction"] =
                "decreasing"
        end

        geo_coord_vars["longitude"] = Variable(
            ("longitude",),
            first_message["distinctLongitudes"],
            cfgrib.COORD_ATTRS["longitude"],
        )
    elseif "geography" in encode_cf && grid_type in GRID_TYPES_2D_NON_DIMENSION_COORDS
        throw("unimplemented")
    else
        throw("unimplemented")
    end

    return geo_dims, geo_shape, geo_coord_vars
end


function build_variable_components(
        index, encode_cf=(), filter_by_keys=Dict(),
        log=LOG, errors="warn", squeeze=true, read_keys=[],
        time_dims=("time", "step")
    )
    data_var_attrs_keys = cfgrib.DATA_ATTRIBUTES_KEYS
    data_var_attrs_keys = [
        data_var_attrs_keys;
        get(cfgrib.GRID_TYPE_MAP, index["gridType"][1], [])
    ]
    data_var_attrs_keys = [data_var_attrs_keys; read_keys]

    data_var_attrs = enforce_unique_attributes(
        index, data_var_attrs_keys,
        filter_by_keys
    )

    coords_map = encode_cf_first(data_var_attrs, encode_cf, time_dims)

    coord_name_key_map = Dict()
    coord_vars = OrderedDict()

    for coord_key in coords_map
        values = index[coord_key]
        if length(values) == 1 && ismissing(values[1])
            #  TODO: Add logging
            #  @warn "Missing from GRIB Stream $(coord_key)"
            continue
        end

        coord_name = coord_key

        if ("vertical" in encode_cf && coord_key == "level"
                && haskey(data_var_attrs, "GRIB_typeOfLevel"))
            coord_name = data_var_attrs["GRIB_typeOfLevel"]
            coord_name_key_map[coord_name] = coord_key
        end

        attributes = Dict(
            "long_name" => "original GRIB coordinate for key:" *
                           "$(coord_key)($(coord_name))",
            "units"     => "1",
        )

        merge!(attributes, copy(get(cfgrib.COORD_ATTRS, coord_name, Dict())))

        data = sort(
            values,
            rev=get(attributes, "stored_direction", "none") == "decreasing"
        )
        dimensions = (coord_name, )

        if squeeze && length(values) == 1
            data = data[1]
            typeof(data) == Array ? nothing : data = [data]
            dimensions = ()
        end

        coord_vars[coord_name] = Variable(dimensions, data, attributes)
    end

    header_dimensions = Tuple(
        d for (d, c)
        in pairs(coord_vars)
        if !squeeze || length(c.data) > 1
    )
    header_shape = Tuple(size(coord_vars[d].data) for d in header_dimensions)

    geo_dims, geo_shape, geo_coord_vars = build_geography_coordinates(
        index, encode_cf, errors)

    dimensions = (header_dimensions..., geo_dims)
    shape = (header_shape..., geo_shape)

    merge!(coord_vars, geo_coord_vars)

    offsets = OrderedDict{NTuple{length(header_dimensions), Int64}, Int}()
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

    return offsets

    return coord_name_key_map
end


#  TODO: Implement filter_by_keys
function enforce_unique_attributes(
        header_values::OrderedDict{String, T} where T <: Array,
        attribute_keys::Array
    )
    attributes = OrderedDict()
    for key in attribute_keys
        values = header_values[key]

        if length(values) > 1
            throw(DatasetBuildError(
                "Attributes are not unique for" *
                "$key: $(values)"
            ))
        end

        value = values[1]

        if !ismissing(value) && !(value in ["missing", "undef", "unknown"])
            attributes["GRIB_" * key] = value
        end
    end

    return attributes
end

#  TODO: Implement filter_by_keys
function enforce_unique_attributes(index::FileIndex, attribute_keys::Array)
    attributes = enforce_unique_attributes(
        index.header_value, attribute_keys
    )

    return attributes
end


function encode_cf_first(
        data_var_attrs::OrderedDict,
        encode_cf::Tuple{Vararg{String}}=("parameter", "time"),
        time_dims::Tuple{Vararg{String}}=("time", "step")
    )

    coords_map = cfgrib.ENSEMBLE_KEYS
    param_id = get(data_var_attrs, "GRIB_paramId", missing)
    data_var_attrs["long_name"] = "original GRIB paramId: $(param_id)"
    data_var_attrs["units"] = "1"

    if "parameter" in encode_cf
        if haskey(data_var_attrs, "GRIB_paramId")
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
        if issubset(time_dims, cfgrib.ALL_REF_TIME_KEYS)
            append!(coords_map, time_dims)
        else
            throw("time_dims $(time_dims) is not a subset of " *
                  "$(cfgrib.ALL_REF_TIME_KEYS)"
            )
        end
    else
        append!(coords_map, cfgrib.DATA_TIME_KEYS)
    end

    append!(coords_map, cfgrib.VERTICAL_KEYS)
    append!(coords_map, cfgrib.SPECTRA_KEYS)

    return coords_map
end
