using AbstractTrees
using ComposableCommands
using Test

@testset "ComposableCommands.jl" begin
    include("core.jl")
    include("interpret.jl")
end
