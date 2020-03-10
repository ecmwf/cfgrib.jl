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
