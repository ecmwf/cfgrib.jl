using DataStructures
using Test


@testset "enforce_unique_attributes" begin
    @test CfGRIB.enforce_unique_attributes(
        OrderedDict("key" => [1]), ["key"]) |> length == 1

    for missing_value in [missing, "undef", "unknown"]
        @test CfGRIB.enforce_unique_attributes(
            OrderedDict("key" => [missing_value]), ["key"]) |> length == 0
    end

    @test_throws(
        CfGRIB.DatasetBuildError,
        CfGRIB.enforce_unique_attributes(OrderedDict("key" => [1, 2]), ["key"])
    )
end


@testset "OnDiskArray" begin
    oda = CfGRIB.OnDiskArray(
        "some_path",
        (4, 3, 2, 1),
        OrderedDict(),
        [1,2,3],
        missing,
        10,
    )

    @test size(oda) == oda.size

    test_file = joinpath(dir_testfiles, "era5-levels-members.grib")
    res = CfGRIB.DataSet(test_file).variables["t"]

    @test res.data isa CfGRIB.OnDiskArray

    @test size(res.data[:, :, 2, 120, 61]) == size(res.data)[1:2]
end


@testset "Variable" begin
    res = CfGRIB.Variable(
        ("lat", ),
        [1, 2, 3],
        Dict("Test" => 10)
    )

    @test res == res
end

@testset "build_data_var_components" begin
    @testset "build_data_var_components_no_encode" begin
        test_file = joinpath(dir_testfiles, "era5-levels-members.grib")
        @test isfile(test_file)

        index = CfGRIB.FileIndex(
            test_file,
            CfGRIB.ALL_KEYS
        )

        @test index["paramId"] == [129, 130]

        CfGRIB.filter!(index, paramId=130)

        @test index["paramId"] == [130]
        #  TODO: Add logging
        dims, data_var, coord_vars = CfGRIB.build_variable_components(
            index
        )

        @test dims == OrderedDict(
            "number" => 10,
            "dataDate" => 2,
            "dataTime" => 2,
            "level" => 2,
            "values" => 7320
        )

        @test size(data_var.data) == (10, 2, 2, 2, 7320)

        data = convert(Array, data_var.data)

        @test sum(data) > 0
    end

    @testset "build_data_var_components_encode_cf_geography" begin
        test_file = joinpath(dir_testfiles, "era5-levels-members.grib")

        index = CfGRIB.FileIndex(
            test_file,
            CfGRIB.ALL_KEYS
        )

        CfGRIB.filter!(index, paramId=130)

        @test index["paramId"] == [130]
        #  TODO: Add logging
        dims, data_var, coord_vars = CfGRIB.build_variable_components(
            index; encode_cf=("geography", )
        )

        @test dims == OrderedDict(
            "number"    => 10,
            "dataDate"  => 2,
            "dataTime"  => 2,
            "level"     => 2,
            "longitude" => 120,
            "latitude"  => 61
        )

        @test size(data_var.data) == (10, 2, 2, 2, 120, 61)

        data = convert(Array, data_var.data)

        @test sum(data) > 0
    end
end


@testset "build_dataset_components_time_dims" begin
    test_file = joinpath(dir_testfiles, "forecast_monthly_ukmo.grib")
    index = CfGRIB.FileIndex(
        test_file,
        CfGRIB.ALL_KEYS
    )

    dims, _, _ = CfGRIB.build_dataset_components(
        index
    )
    @test dims == OrderedDict(
        "latitude"  => 6,
        "longitude" => 11,
        "number"    => 28,
        "step"      => 20,
        "time"      => 8
    )

    dims, _, _ = CfGRIB.build_dataset_components(
        index,
        time_dims=("indexing_time", "verifying_time")
    )
    @test dims == OrderedDict(
        "number" => 28,
        "indexing_time" => 2,
        "verifying_time" => 4,
        "latitude" => 6,
        "longitude" => 11,
    )

    dims, _, _ = CfGRIB.build_dataset_components(
        index,
        time_dims=("indexing_time", "step")
    )
    @test dims == OrderedDict(
        "number" => 28,
        "indexing_time" => 2,
        "step" => 20,
        "latitude" => 6,
        "longitude" => 11
    )
end


@testset "DataSet" begin
    @testset "DataSet_default_encode" begin
        test_file = joinpath(dir_testfiles, "era5-levels-members.grib")
        res = CfGRIB.DataSet(test_file)

        @test "Conventions" in keys(res.attributes)
        @test "institution" in keys(res.attributes)
        @test "history" in keys(res.attributes)

        @test res.attributes["GRIB_edition"] == 1

        @test res.dimensions == OrderedDict(
            "number"        => 10,
            "time"          => 4,
            "isobaricInhPa" => 2,
            "longitude"     => 120,
            "latitude"      => 61
        )

        @test length(res.variables) == 9
    end

    @testset "DataSet_no_encode" begin
        test_file = joinpath(dir_testfiles, "era5-levels-members.grib")
        res = CfGRIB.DataSet(test_file; encode_cf=())

        @test "Conventions" in keys(res.attributes)
        @test "institution" in keys(res.attributes)
        @test "history" in keys(res.attributes)

        @test res.attributes["GRIB_edition"] == 1

        @test res.dimensions == OrderedDict(
            "number"   => 10,
            "dataDate" => 2,
            "dataTime" => 2,
            "level"    => 2,
            "values"   => 7320
        )

        @test length(res.variables) == 9
    end

    @testset "DataSet_cf_time" begin
        test_file = joinpath(dir_testfiles, "era5-levels-members.grib")
        res = CfGRIB.DataSet(test_file; encode_cf=("time", ))

        @test "Conventions" in keys(res.attributes)
        @test "institution" in keys(res.attributes)
        @test "history" in keys(res.attributes)

        @test res.attributes["GRIB_edition"] == 1

        @test res.dimensions == OrderedDict(
            "number" => 10,
            "time"   => 4,
            "level"  => 2,
            "values" => 7320
        )

        @test length(res.variables) == 9
    end

    @testset "DataSet_cf_geography" begin
        test_file = joinpath(dir_testfiles, "era5-levels-members.grib")
        res = CfGRIB.DataSet(test_file; encode_cf=("geography", ))

        @test "Conventions" in keys(res.attributes)
        @test "institution" in keys(res.attributes)
        @test "history" in keys(res.attributes)

        @test res.attributes["GRIB_edition"] == 1

        @test res.dimensions == OrderedDict(
            "number"    => 10,
            "dataDate"  => 2,
            "dataTime"  => 2,
            "level"     => 2,
            "longitude" => 120,
            "latitude"  => 61
        )

        @test length(res.variables) == 9
    end

    @testset "DataSet_cf_vertical" begin
        test_file = joinpath(dir_testfiles, "era5-levels-members.grib")
        res = CfGRIB.DataSet(test_file; encode_cf=("vertical", ))

        @test "Conventions" in keys(res.attributes)
        @test "institution" in keys(res.attributes)
        @test "history" in keys(res.attributes)

        @test res.attributes["GRIB_edition"] == 1

        @test res.dimensions == OrderedDict(
            "number"        => 10,
            "dataDate"      => 2,
            "dataTime"      => 2,
            "isobaricInhPa" => 2,
            "values"        => 7320
        )

        @test length(res.variables) == 9
    end

    @testset "DataSet_gg_surface" begin
        test_file = joinpath(dir_testfiles, "regular_gg_sfc.grib")
        res = CfGRIB.DataSet(test_file)

        @test "Conventions" in keys(res.attributes)
        @test "institution" in keys(res.attributes)
        @test "history" in keys(res.attributes)

        @test res.attributes["GRIB_edition"] == 1

        @test res.dimensions == OrderedDict(
            "longitude" => 192,
            "latitude"  => 96
        )

        @test length(res.variables) == 8

        @test res.variables["latitude"].data[1:2] ≈ [88.57216851, 86.72253095]
    end
end
