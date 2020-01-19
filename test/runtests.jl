using cfgrib
using Test

@testset "cfgrib.jl" begin
    @testset "Indexing" begin
        include("indexing.jl")
    end
end
