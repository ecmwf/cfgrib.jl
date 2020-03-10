using Test

using cfgrib


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
