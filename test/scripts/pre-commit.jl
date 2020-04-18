#!/usr/bin/env julia

using Pkg

cfgribjl_dir = normpath(joinpath(@__DIR__, "..", ".."))

Pkg.activate(cfgribjl_dir); print("\n")

println(
    """
          Running pre-commit hook
    -------------------------------------
    | Testing code imports to catch any |
    |   syntax or dependency problems   |
    -------------------------------------
    """
)

include(joinpath(cfgribjl_dir, "./src/cfgrib.jl"))
