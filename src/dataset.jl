using DataStructures

function build_variable_components(index, encode_cf=(), filter_by_keys=Dict(), log=LOG, errors="warn", squeeze=true, read_keys=[], time_dims=("time", "step"))
    data_var_attrs_keys = cfgrib.DATA_ATTRIBUTES_KEYS
    data_var_attrs_keys = [data_var_attrs_keys; get(cfgrib.GRID_TYPE_MAP, index["gridType"][1], [])]
    data_var_attrs_keys = [data_var_attrs_keys; read_keys]

    data_var_attrs = enforce_unique_attributes(var_index, data_var_attrs_keys, filter_by_keys)

    coords_map = encode_cf_first(data_var_attrs, encode_cf, time_dims)

    coord_name_keymap = Dict()
    coord_vars = OrderedDict()

    for coord_key in coords_map
    end
end

function enforce_unique_attributes(index::cfgrib.FileIndex, attribute_keys::Array, filter_by_keys::Dict)
    attributes = OrderedDict()
    for key in attribute_keys
        values = index[key]

        if length(values) > 1
            throw("Attributes are not unique for $key: $(values)")
        end

        value = values[1]

        if !ismissing(value)
            attributes["GRIB_" * key] = value
        end
    end

    return attributes
end


function encode_cf_first(data_var_attrs::OrderedDict, encode_cf::Tuple{Vararg{String}}=("parameter", "time"), time_dims::Tuple{Vararg{String}}=("time", "step"))
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
            throw("time_dims $(time_dims) is not a subset of $(cfgrib.ALL_REF_TIME_KEYS)")
        end
    else
        append!(coords_map, cfgrib.DATA_TIME_KEYS)
    end

    append!(coords_map, cfgrib.VERTICAL_KEYS)
    append!(coords_map, cfgrib.SPECTRA_KEYS)

    return coords_map
end
