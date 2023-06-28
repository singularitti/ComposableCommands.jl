module CommandComposer

export Flag, Option, AndCommands, OrCommands, RedirectedCommand, Command

abstract type CommandParameter end

"""
    Flag(long_name, short_name, description)

Create a `Flag` object.

# Arguments
- `long_name::String`: the full name of the flag, e.g. "recursive" for a `-r` flag.
- `short_name::String`: the short, usually single-letter, name of the flag, e.g. "r" for a `--recursive` flag.
- `description::String`: a description of the flag for documentation purposes.
"""
struct Flag <: CommandParameter
    long_name::String
    short_name::String
    description::String
    function Flag(long_name, short_name, description)
        if isempty(long_name) && isempty(short_name)
            throw(
                ArgumentError(
                    "at least one of `long_name` or `short_name` must be non-empty!"
                ),
            )
        end
        return new(long_name, short_name, description)
    end
end

"""
    Option(long_name, short_name, description, value)

Create an `Option` object.

# Arguments
- `long_name::String`: the full name of the option, e.g. "file" for a `-f` option.
- `short_name::String`: the short, usually single-letter, name of the option, e.g. "f" for a `--file` option.
- `description::String`: a description of the option for documentation purposes.
- `value::Any`: the value assigned to this option.
"""
struct Option <: CommandParameter
    long_name::String
    short_name::String
    description::String
    value::Any
    function Option(long_name, short_name, description, value)
        if isempty(long_name) && isempty(short_name)
            throw(
                ArgumentError(
                    "at least one of `long_name` or `short_name` must be non-empty!"
                ),
            )
        end
        return new(long_name, short_name, description, value)
    end
end

abstract type AbstractCommand end

"""
    AndCommands(a::AbstractCommand, b::AbstractCommand)

Represents a conjunction of two commands (i.e., both commands are executed).
"""
struct AndCommands <: AbstractCommand
    a::AbstractCommand
    b::AbstractCommand
end

"""
    OrCommands(a::AbstractCommand, b::AbstractCommand)

Represents a disjunction of two commands (i.e., either command is executed).
"""
struct OrCommands <: AbstractCommand
    a::AbstractCommand
    b::AbstractCommand
end

"""
    RedirectedCommand(command::AbstractCommand, redirect::Redirect)

Represents a command with an associated redirection.
"""
struct RedirectedCommand{S,D} <: AbstractCommand
    source::S
    destination::D
    function RedirectedCommand{S,D}(source::S, destination::D) where {S,D}
        if !(S <: AbstractCommand && D <: String || S <: String && D <: AbstractCommand)
            throw(ArgumentError("source and destination cannot be $S and $D."))
        end
        return new{S,D}(source, destination)
    end
end
RedirectedCommand(source::S, destination::D) where {S,D} =
    RedirectedCommand{S,D}(source, destination)

"""
    Command(name, flags, options, arguments, subcommands)

Represents a command to be executed, with associated flags, options, arguments, and subcommands.

# Arguments
- `name::String`: the name of the command.
- `flags::Vector{Flag}`: any flags associated with the command.
- `options::Vector{Option}`: any options associated with the command.
- `arguments::Vector{String}`: any arguments to the command.
- `subcommands::Vector{AbstractCommand}`: any subcommands to be executed in conjunction with the main command.
"""
struct Command <: AbstractCommand
    name::String
    flags::Vector{Flag}
    options::Vector{Option}
    arguments::Vector{String}
    subcommands::Vector{AbstractCommand}
end

include("show.jl")
include("interpret.jl")

end
