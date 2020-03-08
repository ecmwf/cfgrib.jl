using cfgrib
using GRIB

result = cfgrib.from_grib_date_time(20160706, 1944)

@test result == 1467834240
