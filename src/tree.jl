# tree.jl: provide an AbstractTrees.jl interface for command objects

using AbstractTrees

# -- children ---------------------------------------------------------------
# the natural hierarchy of a command is its subcommands; other composite
# command types expose their components as children as well.  we filter out
# `nothing` from redirects so `print_tree` doesn't show empty branches.
AbstractTrees.children(cmd::Command) = cmd.subcommands
AbstractTrees.children(c::AndCommands) = (c.a, c.b)
AbstractTrees.children(c::OrCommands) = (c.a, c.b)
AbstractTrees.children(r::RedirectedCommand) = filter(
    !isnothing,
    (
        (r.source isa AbstractCommand ? r.source : nothing),
        (r.destination isa AbstractCommand ? r.destination : nothing),
    ),
)

# -- node values -----------------------------------------------------------
# what gets printed at each node when using `print_tree` (default is the
# object itself, which is often verbose); offering a short string makes the
# tree much more readable.
AbstractTrees.nodevalue(cmd::Command) = cmd.name
AbstractTrees.nodevalue(::AndCommands) = "&"
AbstractTrees.nodevalue(::OrCommands) = "|"
AbstractTrees.nodevalue(::RedirectedCommand) = "⟨redir⟩"

# -- traits ----------------------------------------------------------------
# guarantee that every node in the tree is some subtype of AbstractCommand;
# this ensures type stability for `TreeIterator` and related helpers.
AbstractTrees.NodeType(::Type{<:AbstractCommand}) = HasNodeType()
AbstractTrees.nodetype(::Type{<:AbstractCommand}) = AbstractCommand

# inform the compiler about eltype of tree iterators so that `collect` works
Base.IteratorEltype(::Type{<:AbstractTrees.TreeIterator{<:AbstractCommand}}) =
    Base.HasEltype()
Base.eltype(::Type{<:AbstractTrees.TreeIterator{<:AbstractCommand}}) = AbstractCommand

# convenience utility for users: gather all nodes below a root
"""
    allnodes(cmd::AbstractCommand) -> Vector{AbstractCommand}

Return a vector containing `cmd` and all of its descendants in
pre‑order (parent before children).  This is simply a thin wrapper over
`collect(AbstractTrees.TreeIterator(cmd))` but is exported for
convenience so callers don’t need to pull in `AbstractTrees`.
"""
allnodes(cmd::AbstractCommand) = collect(AbstractTrees.TreeIterator(cmd))

# allow `for x in cmd` by forwarding to TreeIterator
Base.iterate(cmd::AbstractCommand) = iterate(AbstractTrees.TreeIterator(cmd))
Base.iterate(cmd::AbstractCommand, state) = iterate(AbstractTrees.TreeIterator(cmd), state)
