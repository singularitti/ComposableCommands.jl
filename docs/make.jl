using ComposableCommands
using Documenter

DocMeta.setdocmeta!(ComposableCommands, :DocTestSetup, :(using ComposableCommands); recursive=true)

makedocs(;
    modules=[ComposableCommands],
    authors="singularitti <singularitti@outlook.com> and contributors",
    repo="https://github.com/singularitti/ComposableCommands.jl/blob/{commit}{path}#{line}",
    sitename="ComposableCommands.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://singularitti.github.io/ComposableCommands.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Manual" => [
            "Installation guide" => "installation.md",
        ],
        "API Reference" => "api.md",
        "Developer Docs" => [
            "Contributing" => "developers/contributing.md",
            "Style Guide" => "developers/style-guide.md",
            "Design Principles" => "developers/design-principles.md",
        ],
        "Troubleshooting" => "troubleshooting.md",
    ],
)

deploydocs(;
    repo="github.com/singularitti/ComposableCommands.jl",
    devbranch="main",
)
