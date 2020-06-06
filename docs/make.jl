using Pkg

using Documenter, CfGRIB

makedocs(
    format = Documenter.HTML(
        edit_link = :commit
    ),
    modules = [CfGRIB],
    sitename="CfGRIB.jl Documentation",
    pages = [
        "Home" => "index.md",
    ],
    authors = replace(
        join(Pkg.TOML.parsefile("../Project.toml")["authors"], ", "),
        r" <.*?>" => ""
    )
)
