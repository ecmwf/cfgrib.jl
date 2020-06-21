using CfGRIB
using Test


const dir_tests = abspath(joinpath(dirname(pathof(CfGRIB)), "..", "test"))
const dir_testfiles = abspath(joinpath(dir_tests, "sample-data"))


@testset "CfGRIB.jl" begin
    @testset "Indexing" begin
        include("indexing.jl")
    end

    @testset "CFMessage" begin
        include("cfmessage.jl")
    end

    @testset "Dataset" begin
        include("dataset.jl")
    end

    @testset "Parity" begin
        include("parity.jl")
    end

    @testset "Backends" begin
        include("backends.jl")
    end
end
