using Dates
using GRIB


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
        message::GRIB.Message, date_key="dataDate",
        time_key="dataTime", epoch=DEFAULT_EPOCH
    )
    date = message[date_key]
    time = message[time_key]

    return from_grib_date_time(date, time)
end


#  TODO: This probably won't work translated directly from python
#  check cases where time and step are effectively missing
function build_valid_time(time::Int, step::Int)
    step_s = step * 3600

    data = time + step_s
    dims = ()

    return dims, data
end

function build_valid_time(time::Array{Int, 1}, step::Int)
    step_s = step * 3600

    data = time .+ step_s
    dims = ("time", )

    return dims, data
end

function build_valid_time(time::Int, step::Array{Int, 1})
    step_s = step * 3600

    data = time .+ step_s
    dims = ("step", )

    return dims, data
end

function build_valid_time(time::Array{Int, 1}, step::Array{Int, 1})
    step_s = step * 3600

    if length(time) == 1 && length(step) == 1
        return build_valid_time(time[1], step[1])
    end

    #  TODO: Julia is column major, numpy is row major, not too sure what
    #  the correct approach would be here...
    data = time' .+ step_s
    dims = ("time", "step")
    return dims, data

end

#  TODO: implement other conversion methods, but some seem unused, should these
#  be implemented as well:
#   - to_grib_date_time
#   - from_grib_step
#   - to_grib_step
#   - from_grib_month
