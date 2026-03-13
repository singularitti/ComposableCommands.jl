import Base: show
import AbstractTrees: print_tree

show(io::IO, command::AbstractCommand) = print_tree(io, command)
