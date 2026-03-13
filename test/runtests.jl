using AbstractTrees
using ComposableCommands
using ComposableCommands: as_string
using Test

@testset "ComposableCommands.jl" begin
    include("core.jl")
    include("interpret.jl")
end
