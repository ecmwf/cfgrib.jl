using Dates
using GRIB


# taken from eccodes stepUnits.table
GRIB_STEP_UNITS_TO_SECONDS = [
    60,
    3600,
    86400,
    missing,
    missing,
    missing,
    missing,
    missing,
    missing,
    missing,
    10800,
    21600,
    43200,
    1,
    900,
]
DEFAULT_EPOCH = DateTime(1970, 1, 1, 0, 0)


function from_grib_date_time(date::Int, time::Int; epoch=DEFAULT_EPOCH)
    hour = time ÷ 100
    minute = time % 100
    year = date ÷ 10000
    month = date ÷ 100 % 100
    day = date % 100

    data_datetime = DateTime(year, month, day, hour, minute)

    return Dates.value(Dates.Second(data_datetime - epoch))
end

function from_grib_date_time(
        message::GRIB.Message; date_key="dataDate",
        time_key="dataTime", epoch=DEFAULT_EPOCH
    )
    if !haskey(message, date_key) || !haskey(message, time_key)
        return missing
    end

    date = message[date_key]
    time = message[time_key]

    return from_grib_date_time(date, time, epoch=epoch)
end

function to_grib_date_time(args...; kwargs...)
    throw(ErrorException("Unimplemented"))
end


function from_grib_step(
        message::GRIB.Message,
        step_key="endStep", step_unit_key="stepUnits"
    )
    to_seconds = GRIB_STEP_UNITS_TO_SECONDS[message[step_unit_key]]
    return message[step_key] * to_seconds / 3600.0
end

function to_grib_step(args...; kwargs...)
    throw(ErrorException("Unimplemented"))
end


function from_grib_month(
        message::GRIB.Message,
        verifying_month_key="verifyingMonth",
        epoch=DEFAULT_EPOCH
    )

    if !haskey(message, verifying_month_key)
        return missing
    end

    date = message[verifying_month_key]
    year = date ÷ 100
    month = date % 100
    data_datetime = DateTime(year, month)

    return Dates.value(Dates.Second(data_datetime - epoch))
end

"""
    build_valid_time(time::Int, step::Int)::Tuple{Tuple{},Int64}

Returns a pair of `(dims, data)` based on the type of input, this function
behaves like:

```jldoctest
julia> CfGRIB.build_valid_time(10, 10)
((), 36010)
```
"""
function build_valid_time(time::Int, step::Int)::Tuple{Tuple{},Int64}
    step_s = step * 3600

    data = time + step_s
    dims = ()

    return dims, data
end

"""
    build_valid_time(time::Array{Int, 1}, step::Int)::Tuple{Tuple{String},Array{Int64,1}}

Returns a pair of `(dims, data)` based on the type of input, this function
behaves like:

```jldoctest
julia> CfGRIB.build_valid_time([10], 10)
(("time",), [36010])
```
"""
function build_valid_time(time::Array{Int, 1}, step::Int)::Tuple{Tuple{String},Array{Int64,1}}
    step_s = step * 3600

    data = time .+ step_s
    dims = ("time", )

    return dims, data
end

"""
    build_valid_time(time::Int, step::Array{Int, 1})::Tuple{Tuple{String},Array{Int64,1}}

Returns a pair of `(dims, data)` based on the type of input, this function
behaves like:

```jldoctest
julia> CfGRIB.build_valid_time(1, [10])
(("step",), [36001])
```
"""
function build_valid_time(time::Int, step::Array{Int, 1})::Tuple{Tuple{String},Array{Int64,1}}
    step_s = step * 3600

    data = time .+ step_s
    dims = ("step", )

    return dims, data
end

"""
    build_valid_time(time::Array{Int, 1}, step::Array{Int, 1})::Tuple{Tuple{},Int64}

Returns a pair of `(dims, data)` based on the type of input, this function
behaves like:

```jldoctest
julia> CfGRIB.build_valid_time([10], [10])
((), 36010)
```
"""
function build_valid_time(time::Array{Int, 1}, step::Array{Int, 1})::Tuple{Tuple{},Int64}
    step_s = step * 3600

    if length(time) == 1 && length(step) == 1
        return build_valid_time(time[1], step[1])
    end

    data = time' .+ step_s
    dims = ("time", "step")
    return dims, data
end

COMPUTED_KEYS = Dict(
    "time" => (from_grib_date_time, to_grib_date_time),
    #  TODO: Actually applying the from_grib_step function results in different
    #  values to cfgrib.py...?
    # "step" => (from_grib_step, to_grib_step),
    "valid_time" => (
        message -> from_grib_date_time(message, date_key="validityDate", time_key="validityTime"),
        message -> to_grib_date_time(message, date_key="validityDate", time_key="validityTime"),
    ),
    "verifying_time" => (from_grib_month, m -> throw(ErrorException("Unimplemented"))),
    "indexing_time" => (
        message -> from_grib_date_time(message, date_key="indexingDate", time_key="indexingTime"),
        message -> to_grib_date_time(message, date_key="indexingDate", time_key="indexingTime"),
    ),
)

@doc """
    COMPUTED_KEYS::Dict{String,Tuple{Function,Function}}

Dictionary which maps a key to a conversion method. The first function is the
'to' conversion, the second is 'from'.

TODO: Actually applying the `from_grib_step` function results in different values
to cfgrib.py, so `step -> (from_grib_step, to_grib_step)` is currently disabled.

Currently converts:

```
    "time" => (from_grib_date_time, to_grib_date_time)

    "valid_time" => (
        message -> from_grib_date_time(message, date_key="validityDate", time_key="validityTime"),
        message -> to_grib_date_time(message, date_key="validityDate", time_key="validityTime"),
    )

    "verifying_time" => (from_grib_month, m -> throw(ErrorException("Unimplemented")))

    "indexing_time" => (
        message -> from_grib_date_time(message, date_key="indexingDate", time_key="indexingTime"),
        message -> to_grib_date_time(message, date_key="indexingDate", time_key="indexingTime"),
    )
```

# Example

A GRIB message containing `20160501` as the date key and `0` as the time key
would end up calling:

```jldoctest
julia> CfGRIB.COMPUTED_KEYS["time"](20160501, 0)
1462060800
```
""" COMPUTED_KEYS


"""
    read_message(message::GRIB.Message, key::String)

Reads a specific key from a GRIB.jl message. Attempts to convert the raw value
associated with that key using the `COMPUTED_KEYS` mapping to `from_grib_*`
functions.

See also: [`compute_keys`](@ref)
"""
function read_message(message::GRIB.Message, key::String)
    value = missing

    if key in keys(COMPUTED_KEYS)
        value = COMPUTED_KEYS[key][1](message)
    end

    if ismissing(value)
        value = haskey(message, key) ? message[key] : missing
    end

    value = value isa Array ? Tuple(value) : value

    return value
end

#  TODO: implement other conversion methods, but some seem unused, should these
#  be implemented as well:
#   - to_grib_date_time
#   - from_grib_step
#   - to_grib_step
