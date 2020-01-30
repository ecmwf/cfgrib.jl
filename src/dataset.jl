using DataStructures

function enforce_unique_attributes(index::FileIndex, attribute_keys)
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
