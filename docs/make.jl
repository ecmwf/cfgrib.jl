using Pkg;
Pkg.activate(joinpath(@__DIR__, "..")); Pkg.instantiate()
Pkg.activate(); Pkg.instantiate()

pushfirst!(LOAD_PATH, joinpath(@__DIR__, ".."))

using Documenter, CfGRIB

makedocs(
    # format = Documenter.HTML(
    #     edit_link = :commit
    # ),
    modules = [CfGRIB],
    sitename="CfGRIB.jl",
    pages = [
        "Home" => "index.md",
        "Library" => "library.md",
    ],
    authors = replace(
        join(Pkg.TOML.parsefile("../Project.toml")["authors"], ", "),
        r" <.*?>" => ""
    )
)
