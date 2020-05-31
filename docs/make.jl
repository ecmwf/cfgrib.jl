using Pkg

using Documenter, cfgrib

makedocs(
    format = Documenter.HTML(
        edit_link = :commit
    ),
    modules = [cfgrib],
    sitename="cfgrib.jl Documentation",
    pages = [
        "Home" => "index.md",
    ],
    authors = replace(
        join(Pkg.TOML.parsefile("../Project.toml")["authors"], ", "),
        r" <.*?>" => ""
    )
)
