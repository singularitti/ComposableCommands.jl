using CommandComposer
using Documenter

DocMeta.setdocmeta!(CommandComposer, :DocTestSetup, :(using CommandComposer); recursive=true)

makedocs(;
    modules=[CommandComposer],
    authors="singularitti <singularitti@outlook.com> and contributors",
    repo="https://github.com/singularitti/CommandComposer.jl/blob/{commit}{path}#{line}",
    sitename="CommandComposer.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://singularitti.github.io/CommandComposer.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/singularitti/CommandComposer.jl",
    devbranch="main",
)
