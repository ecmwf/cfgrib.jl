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
        "Library" => Any[
            "Backends"  => "lib/backends.md",
            "CFMessage" => "lib/cfmessage.md",
            "Constants" => "lib/constants.md",
            "Dataset"   => "lib/dataset.md",
            "Indexing"  => "lib/indexing.md",
        ],
    ]
)

deploydocs(
    repo = "github.com/RobertRosca/cfgrib.jl",
    devbranch="dev",
    push_preview=true,
)
