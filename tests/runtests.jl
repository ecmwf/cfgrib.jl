using Test

using cfgrib


const dir_tests = abspath(joinpath(dirname(pathof(cfgrib)), "..", "tests"))
const dir_testfiles = abspath(joinpath(dir_tests, "sample-data"))


@testset "cfgrib.jl" begin
    @testset "Indexing" begin
        include("indexing.jl")
    end

    @testset "CFMessage" begin
        include("cfmessage.jl")
    end

    @testset "Dataset" begin
        include("dataset.jl")
    end
end
