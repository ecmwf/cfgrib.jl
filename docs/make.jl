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
        "Manual"  => "man/guide.md",
        "Library" => Any[
            # "Public" => "lib/public.md",
            "Internals" => map(
                s -> "lib/internals/$(s)",
                sort(readdir(joinpath(@__DIR__, "src/lib/internals")))
            ),
        ],
    ]
)

deploydocs(
    repo = "github.com/ecmwf/cfgrib.jl",
    devbranch="dev",
    push_preview=true,
)
