using AbstractTrees:
    AbstractTrees,
    ImplicitParents,
    ImplicitSiblings,
    IndexedChildren,
    NodeTypeUnknown,
    PreOrderDFS

import AbstractTrees:
    children,
    nodevalue,
    ParentLinks,
    SiblingLinks,
    ChildIndexing,
    NodeType,
    nodetype,
    childrentype,
    childtype,
    childstatetype,
    printnode,
    TreeIterator,
    parent,
    treesize,
    treebreadth,
    treeheight

# Children
# The natural hierarchy of a command is its subcommands. Other composite
# command types expose their components as children as well.
children(cmd::Command) = cmd.subcommands
children(c::AndCommands) = (c.a, c.b)
children(c::OrCommands) = (c.a, c.b)
children(r::RedirectedCommand{<:AbstractCommand,<:String}) = (r.source,)
children(r::RedirectedCommand{<:String,<:AbstractCommand}) = (r.destination,)

# Node values
# These labels are printed by `print_tree`. By default the object itself would
# be shown, which is rarely what the user wants. For `Command`, we render the
# name together with its parameters and arguments on a single line, and only
# show subcommands as children.
function _commandlabel(cmd::Command)
    parts = String[cmd.name]
    # Parameters follow shell syntax
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
    # Positional arguments come last.
    append!(parts, cmd.arguments)
    return join(parts, ' ')
end

nodevalue(cmd::Command) = _commandlabel(cmd)
# Composite operations use compact shell-like labels in tree output
nodevalue(::AndCommands) = "&&"
nodevalue(::OrCommands) = "|"
# Redirect nodes show the direction and filename. The actual command appears as
# a child if it is an `AbstractCommand`.
function nodevalue(r::RedirectedCommand)
    if r.source isa AbstractCommand && r.destination isa String
        return "> " * r.destination
    elseif r.source isa String && r.destination isa AbstractCommand
        return "< " * r.source
    else
        return "redir"
    end
end

# Traits
# Command trees are heterogeneous: a `RedirectedCommand` can contain a
# `Command`, `AndCommands`, or `OrCommands`. Declaring the node type unknown
# ensures AbstractTrees uses cursors that can traverse mixed node types.
ParentLinks(::Type{<:AbstractCommand}) = ImplicitParents()

SiblingLinks(::Type{<:AbstractCommand}) = ImplicitSiblings()

ChildIndexing(::Type{<:AbstractCommand}) = IndexedChildren()

NodeType(::Type{<:AbstractCommand}) = NodeTypeUnknown()

nodetype(::Type{<:AbstractCommand}) = AbstractCommand

childrentype(::Type{Command}) = Vector{AbstractCommand}
childrentype(::Type{AndCommands{A,B}}) where {A<:AbstractCommand,B<:AbstractCommand} =
    Tuple{A,B}
childrentype(::Type{OrCommands{A,B}}) where {A<:AbstractCommand,B<:AbstractCommand} =
    Tuple{A,B}
childrentype(::Type{RedirectedCommand{S,D}}) where {S<:AbstractCommand,D<:String} = Tuple{S}
childrentype(::Type{RedirectedCommand{S,D}}) where {S<:String,D<:AbstractCommand} = Tuple{D}

childtype(::Type{<:AbstractCommand}) = AbstractCommand
childstatetype(::Type{<:AbstractCommand}) = Union{Nothing,Tuple{AbstractCommand,Int}}

# Inform the compiler about iterator eltype so that `collect` works
Base.IteratorEltype(::Type{<:TreeIterator{<:AbstractCommand}}) = Base.HasEltype()
Base.eltype(::Type{<:TreeIterator{<:AbstractCommand}}) = AbstractCommand

"""
    printnode(io::IO, cmd::AbstractCommand; kw...)

Print a compact tree label for `cmd`.

`Cmd` has native `&` and `pipeline` composition, but these shorter labels make
tree output read more like shell syntax. This affects display only.
"""
# Print labels directly rather than showing quoted strings
printnode(io::IO, cmd::AbstractCommand; kw...) = print(io, nodevalue(cmd))

# Provide a simple default constructor so users can write
# `AbstractTrees.TreeIterator(cmd)` without running into a method error.
TreeIterator(cmd::AbstractCommand) = PreOrderDFS(cmd)

# `ascend(select, root, node)` uses this method when parent links are not stored
# directly on the nodes. Search the rooted tree by identity so commands can be
# reused as values without forcing parent pointers into the node structs.
function parent(root::AbstractCommand, node::AbstractCommand)
    root === node && return nothing
    for child in children(root)
        child === node && return root
        found_parent = parent(child, node)
        isnothing(found_parent) || return found_parent
    end
    return nothing
end

treesize(node::AbstractCommand) = 1 + sum(treesize, children(node); init=0)

function treebreadth(node::AbstractCommand)
    if isempty(children(node))
        return 1
    end
    return sum(treebreadth, children(node); init=0)
end

function treeheight(node::AbstractCommand)
    if isempty(children(node))
        return 0
    end
    return 1 + maximum(treeheight, children(node); init=0)
end

# Convenience utilities
"""
    collectnodes(cmd::AbstractCommand) -> Vector{AbstractCommand}

Return a vector containing `cmd` and all of its descendants in pre-order
(parent before children).
"""
collectnodes(cmd::AbstractCommand) = collect(TreeIterator(cmd))

# Allow `for x in cmd` by forwarding to `TreeIterator`
Base.iterate(cmd::AbstractCommand) = iterate(TreeIterator(cmd))
Base.iterate(cmd::AbstractCommand, state) = iterate(TreeIterator(cmd), state)
