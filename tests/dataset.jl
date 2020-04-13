using Test

using cfgrib
using DataStructures


@testset "enforce_unique_attributes" begin
    @test cfgrib.enforce_unique_attributes(
        OrderedDict("key" => [1]), ["key"]) |> length == 1

    for missing_value in [missing, "missing", "undef", "unknown"]
        @test cfgrib.enforce_unique_attributes(
            OrderedDict("key" => [missing_value]), ["key"]) |> length == 0
    end

    @test_throws(
        cfgrib.DatasetBuildError,
        cfgrib.enforce_unique_attributes(OrderedDict("key" => [1, 2]), ["key"])
    )
end


@testset "OnDiskArray" begin
    oda = cfgrib.OnDiskArray(
        "some_path",
        (4, 3, 2, 1),
        OrderedDict(),
        [1,2,3],
        missing,
        10,
        Float32
    )

    @test size(oda) == oda.size
end


@testset "Variable" begin
    res = cfgrib.Variable(
        ("lat", ),
        [1, 2, 3],
        Dict("Test" => 10)
    )

    @test res == res
end


@testset "build_data_var_components_no_encode" begin
    test_file = joinpath(dir_testfiles, "era5-levels-members.grib")
    @test isfile(test_file)

    index = cfgrib.FileIndex(
        test_file,
        cfgrib.ALL_KEYS
    )

    @test index["paramId"] == [129, 130]

    cfgrib.filter!(index, paramId=130)

    @test index["paramId"] == [130]

    dims, data_var, coord_vars = cfgrib.build_variable_components(
        index; log=missing
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

    index = cfgrib.FileIndex(
        test_file,
        cfgrib.ALL_KEYS
    )

    cfgrib.filter!(index, paramId=130)

    @test index["paramId"] == [130]

    dims, data_var, coord_vars = cfgrib.build_variable_components(
        index; encode_cf=("geography", ), log=missing
    )

    @test dims == OrderedDict(
        "number"    => 10,
        "dataDate"  => 2,
        "dataTime"  => 2,
        "level"     => 2,
        "longitude" => 120,
        "latitude"  => 61
    )

    #  TODO: Another area where the row/column major issue affects how the
    #  longitude/latitude area accessed
    @test size(data_var.data) == (10, 2, 2, 2, 120, 61)

    data = convert(Array, data_var.data)

    @test sum(data) > 0
end
