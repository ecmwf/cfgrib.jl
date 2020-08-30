using Pkg

pushfirst!(LOAD_PATH, joinpath(@__DIR__, ".."))

Pkg.activate(joinpath(@__DIR__))
# Pkg.instantiate()
# Pkg.activate(); Pkg.instantiate()

using Documenter, CfGRIB

makedocs(
    modules = [CfGRIB],
    clean = false,
    sitename="CfGRIB.jl",
    doctest = false,
    pages = [
        "Home"    => "index.md",
        "Manual"  => "man/quick-start-guide.md",
    ]
)

deploydocs(
    repo = "github.com/RobertRosca/cfgrib.jl",
    devbranch="dev",
    push_preview=true,
)
