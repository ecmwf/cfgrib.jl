#!/usr/bin/env julia

using Pkg

cfgribjl_dir = normpath(joinpath(@__DIR__, "..", ".."))

Pkg.activate(cfgribjl_dir); print("\n")

println(
    """
           Running pre-push hook
    -------------------------------------
    |  Tests run here while GRIB.jl is  |
    | missing from the registry as that |
    |  breaks CI testing functionality  |
    -------------------------------------
    """
)

include(joinpath(cfgribjl_dir, "./tests/runtests.jl"))
