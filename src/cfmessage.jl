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

function from_grib_date_time(message::GRIB.Message, date_key="dataDate", time_key="dataTime", epoch=DEFAULT_EPOCH)
    date = message[date_key]
    time = message[time_key]

    return from_grib_date_time(date, time)
end
