import Base: show
import AbstractTrees: print_tree

# simple show method that utilizes AbstractTrees to draw a real tree
show(io::IO, command::AbstractCommand) = print_tree(io, command)

