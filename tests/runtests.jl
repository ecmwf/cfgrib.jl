using cfgrib
using Test

@testset "cfgrib.jl" begin
    @testset "Indexing" begin
        include("indexing.jl")
    end

    @testset "CFMessage" begin
        include("cfmessage.jl")
    end
end
