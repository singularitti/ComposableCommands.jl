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
# what gets printed at each node when using `print_tree`.  by default the
# object itself would be shown, which is rarely what the user wants; for
# `Command` we prefer to render the name together with its *parameters* and
# *arguments* on a single line, and only show subcommands as children.
function _cmdlabel(cmd::Command)
    parts = String[cmd.name]
    # parameters (flags/options) follow shell syntax
    for p in values(cmd.parameters)
        if p isa ShortFlag
            push!(parts, "-" * p.name)
        elseif p isa LongFlag
            push!(parts, "--" * p.name)
        elseif p isa ShortOption
            push!(parts, "-" * p.name, string(p.value))
        elseif p isa LongOption
            push!(parts, "--" * p.name * "=" * string(p.value))
        end
    end
    # positional arguments come last
    append!(parts, cmd.arguments)
    return join(parts, ' ')
end

AbstractTrees.nodevalue(cmd::Command) = _cmdlabel(cmd)

# composite operations should use familiar shell operators rather than
# Julia-specific notation.  note that `AndCommands` here does *not* implement
# shell `&&` semantics (see discussion in docs/tests) but displaying `&&`
# is more shell-like than Julia's `&`.
AbstractTrees.nodevalue(::AndCommands) = "&&"
AbstractTrees.nodevalue(::OrCommands) = "|"          # pipe

# redirect nodes simply show the direction and filename; the actual command
# appears as a child if it is an AbstractCommand.
function AbstractTrees.nodevalue(r::RedirectedCommand)
    if r.source isa AbstractCommand && r.destination isa String
        return "> " * r.destination
    elseif r.source isa String && r.destination isa AbstractCommand
        return "< " * r.source
    else
        return "redir"
    end
end

# -- traits ----------------------------------------------------------------
# guarantee that every node in the tree is some subtype of AbstractCommand;
# this ensures type stability for `TreeIterator` and related helpers.
AbstractTrees.NodeType(::Type{<:AbstractCommand}) = HasNodeType()
AbstractTrees.nodetype(::Type{<:AbstractCommand}) = AbstractCommand

# inform the compiler about eltype of tree iterators so that `collect` works
Base.IteratorEltype(::Type{<:AbstractTrees.TreeIterator{<:AbstractCommand}}) =
    Base.HasEltype()
Base.eltype(::Type{<:AbstractTrees.TreeIterator{<:AbstractCommand}}) = AbstractCommand

# provide a simple default constructor so users can write
# `AbstractTrees.TreeIterator(cmd)` without running into a method error.
AbstractTrees.TreeIterator(cmd::AbstractCommand) = AbstractTrees.PreOrderDFS(cmd)

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
