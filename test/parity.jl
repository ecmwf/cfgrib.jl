using DataStructures
using Test

using cfgrib

#  Setup for pycall tests - done by travis, uncomment for manual run
# using Conda; ENV["PYTHON"] = Conda.PYTHONDIR
# using Pkg
# Pkg.build("PyCall")

# Conda.add_channel("conda-forge")
# Conda.add("cfgrib")

using PyCall


@testset "era5-levels-members DataSet parity" begin
    test_file = joinpath(dir_testfiles, "era5-levels-members.grib")
    res = cfgrib.DataSet(test_file)

    @testset "Variables" begin
        @test res.variables["number"].dimensions == ("number",)
        @test res.variables["number"].data == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        @test res.variables["number"].attributes == Dict(
            "units" => "1",
            "long_name" => "ensemble member numerical id",
            "standard_name" => "realization"
        )

        @test res.variables["time"].dimensions == ("time",)
        @test res.variables["time"].data == [
            1483228800, 1483272000, 1483315200, 1483358400
        ]
        @test res.variables["time"].attributes == Dict(
            "units" => "seconds since 1970-01-01T00:00:00",
            "calendar" => "proleptic_gregorian",
            "long_name" => "initial time of forecast",
            "standard_name" => "forecast_reference_time"
        )

        @test res.variables["step"].dimensions == ()
        @test res.variables["step"].data == 0 #  In python this is a float
        @test res.variables["step"].attributes == Dict(
            "units" => "hours",
            "long_name" => "time since forecast_reference_time",
            "standard_name" => "forecast_period"
        )

        @test res.variables["isobaricInhPa"].dimensions == ("isobaricInhPa",)
        @test res.variables["isobaricInhPa"].data == [850, 500]
        @test res.variables["isobaricInhPa"].attributes == Dict(
            "units" => "hPa",
            "stored_direction" => "decreasing",
            "long_name" => "pressure",
            "standard_name" => "air_pressure",
            "positive" => "down"
        )

        @test res.variables["latitude"].dimensions == ("latitude",)
        @test res.variables["latitude"].data == [
            90.,   87.,  84.,  81.,  78.,  75.,  72.,  69.,  66.,  63.,  60.,
            57.,   54.,  51.,  48.,  45.,  42.,  39.,  36.,  33.,  30.,  27.,
            24.,   21.,  18.,  15.,  12.,   9.,   6.,   3.,   0.,  -3.,  -6.,
            -9.,  -12., -15., -18., -21., -24., -27., -30., -33., -36., -39.,
            -42., -45., -48., -51., -54., -57., -60., -63., -66., -69., -72.,
            -75., -78., -81., -84., -87., -90.
        ]
        @test res.variables["latitude"].attributes == Dict(
            "units" => "degrees_north",
            "stored_direction" => "decreasing",
            "long_name" => "latitude",
            "standard_name" => "latitude"
        )

        @test res.variables["longitude"].dimensions == ("longitude",)
        @test res.variables["longitude"].data == [
            0.,   3.,   6.,   9.,  12.,  15.,  18.,  21.,  24.,  27.,  30.,
            33.,  36.,  39.,  42.,  45.,  48.,  51.,  54.,  57.,  60.,  63.,
            66.,  69.,  72.,  75.,  78.,  81.,  84.,  87.,  90.,  93.,  96.,
            99., 102., 105., 108., 111., 114., 117., 120., 123., 126., 129.,
            132., 135., 138., 141., 144., 147., 150., 153., 156., 159., 162.,
            165., 168., 171., 174., 177., 180., 183., 186., 189., 192., 195.,
            198., 201., 204., 207., 210., 213., 216., 219., 222., 225., 228.,
            231., 234., 237., 240., 243., 246., 249., 252., 255., 258., 261.,
            264., 267., 270., 273., 276., 279., 282., 285., 288., 291., 294.,
            297., 300., 303., 306., 309., 312., 315., 318., 321., 324., 327.,
            330., 333., 336., 339., 342., 345., 348., 351., 354., 357.
        ]
        @test res.variables["longitude"].attributes == Dict(
            "units" => "degrees_east",
            "long_name" => "longitude",
            "standard_name" => "longitude"
        )

        @test res.variables["valid_time"].dimensions == ("time",)
        @test res.variables["valid_time"].data == [
            1.4832288e+09, 1.4832720e+09, 1.4833152e+09, 1.4833584e+09
        ]
        @test res.variables["valid_time"].attributes == Dict(
            "units" => "seconds since 1970-01-01T00:00:00",
            "calendar" => "proleptic_gregorian",
            "long_name" => "time",
            "standard_name" => "time"
    )
    end

    @testset "OnDiskArray" begin
        @test res.variables["z"].dimensions == (
            "number", "time", "isobaricInhPa", "longitude", "latitude"
        )
        @test typeof(res.variables["z"].data) == cfgrib.OnDiskArray
        @test size(res.variables["z"].data) == (10, 4, 2, 120, 61)
        @test_broken res.variables["z"].missing_value == 9999
        #  Currently these are not `OrderedDict`, and in the wrong order
        #  TODO: Make these into 'OrderedDict', and order correctly
        @test_broken typeof(res.variables["z"].attributes) == OrderedDict
        @test res.variables["z"].attributes == OrderedDict(
            "GRIB_paramId"                            => 129,
            "GRIB_shortName"                          => "z",
            "GRIB_units"                              => "m**2 s**-2",
            "GRIB_name"                               => "Geopotential",
            "GRIB_cfName"                             => "geopotential",
            "GRIB_cfVarName"                          => "z",
            "GRIB_dataType"                           => "an",
            "GRIB_missingValue"                       => 9999,
            "GRIB_numberOfPoints"                     => 7320,
            "GRIB_totalNumber"                        => 10,
            "GRIB_typeOfLevel"                        => "isobaricInhPa",
            "GRIB_NV"                                 => 0,
            "GRIB_stepUnits"                          => 1,
            "GRIB_stepType"                           => "instant",
            "GRIB_gridType"                           => "regular_ll",
            "GRIB_gridDefinitionDescription"          => "Latitude/Longitude Grid",
            "GRIB_Nx"                                 => 120,
            "GRIB_iDirectionIncrementInDegrees"       => 3.0,
            "GRIB_iScansNegatively"                   => 0,
            "GRIB_longitudeOfFirstGridPointInDegrees" => 0.0,
            "GRIB_longitudeOfLastGridPointInDegrees"  => 357.0,
            "GRIB_Ny"                                 => 61,
            "GRIB_jDirectionIncrementInDegrees"       => 3.0,
            "GRIB_jPointsAreConsecutive"              => 0,
            "GRIB_jScansPositively"                   => 0,
            "GRIB_latitudeOfFirstGridPointInDegrees"  => 90.0,
            "GRIB_latitudeOfLastGridPointInDegrees"   => -90.0,
            "long_name"                               => "Geopotential",
            "units"                                   => "m**2 s**-2",
            "standard_name"                           => "geopotential",
            "coordinates"                             => "number time step isobaricInhPa latitude longitude valid_time"
        )
        #  Should be approx. equal to python:
        #    `res.variables["z"].data[:, :, 1, 1, 1]`
        @test res.variables["z"].data[:, :, 2, 2, 2] ≈ [
            51213.703 51188.277 50836.094 50185.605
            51216.605 51180.03  50833.027 50210.992
            51232.766 51160.65  50823.082 50199.85
            51203.06  51182.15  50816.246 50177.18
            51235.203 51181.234 50823.41  50182.023
            51207.727 51179.25  50813.094 50190.875
            51210.867 51179.35  50818.527 50183.945
            51193.94  51153.36  50794.383 50159.473
            51203.395 51183.875 50835.9   50207.61
            51197.383 51183.77  50819.78  50192.44
        ]
        @test size(res.variables["z"].data[1, 1, 1, :, :]) == (120, 61) # ' vs python
        #  Should be approx. equal to python:
        #    `res.variables["z"].data[0, 0, 0, :, :][:4, :4]`
        #  Used `adjoint` explicitly for clarity, the ' operator works here too
        @test adjoint(res.variables["z"].data[1, 1, 1, :, :])[1:4, 1:4] ≈ [
            14201.754 14201.754 14201.754 14201.754
            14323.254 14333.129 14342.879 14353.504
            14235.629 14252.129 14266.254 14275.879
            14104.254 14085.879 14069.504 14048.379
        ]
        #  Should be approx. equal to python:
        #    `res.variables["z"].data[0, 0, 0, :, :][-4:, -4:]`
        @test adjoint(res.variables["z"].data[1, 1, 1, :, :])[end-3:end, end-3:end] ≈ [
            12140.004 12226.504 12312.629 12406.004
            12417.629 12470.379 12520.129 12568.629
            12633.879 12658.754 12682.879 12705.879
            12660.379 12660.379 12660.379 12660.379
        ]

        @test res.variables["t"].dimensions == (
            "number", "time", "isobaricInhPa", "longitude", "latitude"
        )
        @test typeof(res.variables["t"].data) == cfgrib.OnDiskArray
        @test size(res.variables["t"].data) == (10, 4, 2, 120, 61)
        @test_broken res.variables["t"].missing_value == 9999
        #  TODO: Make these into 'OrderedDict', and order correctly
        @test_broken typeof(res.variables["t"].attributes) == OrderedDict
        @test res.variables["t"].attributes == OrderedDict(
            "GRIB_paramId"                            => 130,
            "GRIB_shortName"                          => "t",
            "GRIB_units"                              => "K",
            "GRIB_name"                               => "Temperature",
            "GRIB_cfName"                             => "air_temperature",
            "GRIB_cfVarName"                          => "t",
            "GRIB_dataType"                           => "an",
            "GRIB_missingValue"                       => 9999,
            "GRIB_numberOfPoints"                     => 7320,
            "GRIB_totalNumber"                        => 10,
            "GRIB_typeOfLevel"                        => "isobaricInhPa",
            "GRIB_NV"                                 => 0,
            "GRIB_stepUnits"                          => 1,
            "GRIB_stepType"                           => "instant",
            "GRIB_gridType"                           => "regular_ll",
            "GRIB_gridDefinitionDescription"          => "Latitude/Longitude Grid",
            "GRIB_Nx"                                 => 120,
            "GRIB_iDirectionIncrementInDegrees"       => 3.0,
            "GRIB_iScansNegatively"                   => 0,
            "GRIB_longitudeOfFirstGridPointInDegrees" => 0.0,
            "GRIB_longitudeOfLastGridPointInDegrees"  => 357.0,
            "GRIB_Ny"                                 => 61,
            "GRIB_jDirectionIncrementInDegrees"       => 3.0,
            "GRIB_jPointsAreConsecutive"              => 0,
            "GRIB_jScansPositively"                   => 0,
            "GRIB_latitudeOfFirstGridPointInDegrees"  => 90.0,
            "GRIB_latitudeOfLastGridPointInDegrees"   => -90.0,
            "long_name"                               => "Temperature",
            "units"                                   => "K",
            "standard_name"                           => "air_temperature",
            "coordinates"                             => "number time step isobaricInhPa latitude longitude valid_time",
        )
        #  Should be approx. equal to python:
        #    `res.variables["t"].data[:, :, 0, 1, 2]`
        @test res.variables["t"].data[:, :, 1, 3, 2] ≈ [
            252.73932 253.1473  252.33952 253.19273
            252.73364 253.0484  252.51244 253.55228
            252.90796 253.02562 252.53241 253.17216
            252.62859 252.69759 252.48486 253.37857
            252.89291 253.22601 252.22084 254.01117
            252.91525 253.18896 252.48277 254.20941
            252.78569 253.13112 252.4354  253.75746
            252.38048 252.64601 252.12773 253.89052
            252.68658 252.9497  252.17213 254.07466
            252.59758 252.99641 252.4409  253.73424
        ]
        @test size(res.variables["t"].data[1, 1, 1, :, :]) == (120, 61) # ' vs python
        #  Should be approx. equal to python:
        #    `res.variables["t"].data[0, 0, 0, :, :][:4, :4]`
        @test adjoint(res.variables["t"].data[1, 1, 1, :, :])[1:4, 1:4] ≈ [
            252.66315 252.66315 252.66315 252.66315
            252.61041 252.68658 252.73932 252.78229
            251.11041 251.36627 251.6026  251.8487
            253.93658 254.41315 254.57526 254.62994
        ]
        #  Should be approx. equal to python:
        #    `res.variables["t"].data[0, 0, 0, :, :][-4:, -4:]`
        @test adjoint(res.variables["t"].data[1, 1, 1, :, :])[end-3:end, end-3:end] ≈ [
            260.59283 260.75104 260.6983  260.6983
            259.23737 259.14752 259.04987 258.8897
            258.56158 258.40143 258.27643 258.1983
            258.5401  258.5401  258.5401  258.5401
        ]
    end
end


cfgrib_dataset_py = pyimport("cfgrib.dataset")

test_files = [
    # "era5-levels-corrupted.grib",# - skip corrupted file tests
    "era5-levels-members.grib",
    "fields_with_missing_values.grib",
    # "hpa_and_pa.grib",# - DatasetBuildError("multiple values for unique key, try re-open the file with one of
    # "lambert_grid.grib",# - TODO: build_geography_coordinates unimplemented for this
    "multi_param_on_multi_dims.grib",
    # "reduced_gg.grib", - TODO: investigate segfault in GRIB.jl
    "regular_gg_ml.grib",
    "regular_gg_ml_g2.grib",
    "regular_gg_pl.grib",
    "regular_gg_sfc.grib",
    "regular_gg_wrong_increment.grib",
    "regular_ll_msl.grib",
    "regular_ll_sfc.grib",
    "regular_ll_wrong_increment.grib",
    "scanning_mode_64.grib",
    # "spherical_harmonics.grib", - ecCodes provides no latitudes/longitudes for gridType='sh'
    "t_analysis_and_fc_0.grib",
    # "t_on_different_level_types.grib", - DatasetBuildError("multiple values for unique key, try re-open the file with one of
    # "tp_on_different_grid_resolutions.grib", - DatasetBuildError("multiple values for unique key, try re-open the file with one of
    # "uv_on_different_levels.grib" - cfgrib.dataset.DatasetBuildError: key present and new value is different
]

attributes_key_blacklist = [
    "history"
]

python_type_mapping = Dict(
    "<class 'cfgrib.dataset.Variable'>" => cfgrib.Variable,
    "<class 'cfgrib.dataset.OnDiskArray'>" => cfgrib.OnDiskArray
)

@testset "pycall tests for $test_file" for test_file in test_files
    # Leave print here in case of segfault/hard crash
    println("\t\t pycall tests for", test_file)
    test_file_path = joinpath(dir_testfiles, test_file)
    res_py = cfgrib_dataset_py.open_file(test_file_path)
    res = cfgrib.DataSet(test_file_path)

    res_py_attributes = copy(res_py.attributes)
    [delete!(res_py_attributes, key) for key in attributes_key_blacklist]
    [delete!(res.attributes, key) for key in attributes_key_blacklist]
    @test res.attributes == res_py_attributes

    @test res.dimensions == res_py.dimensions

    @test Set(keys(res_py.variables)) == Set(keys(res.variables))

    @testset "variable $var" for var in keys(res.variables)
        var_jl = res.variables[var]
        var_py = res_py.variables[var]
        @test Set(var_jl.dimensions) == Set(var_py.dimensions)

        var_type_py = pystr(py"type($(res_py.variables[var]))")

        # TODO: Add in tests for variables
        # if var_type_py in keys(python_type_mapping)
        #     @test
        # else
        # end
    end
end
