module CommandComposer

export Flag,
    Option, AndCommands, OrCommands, CommandPipe, Redirect, CommandRedirect, Command

abstract type CommandParameter end

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

struct AndCommands <: AbstractCommand
    a::AbstractCommand
    b::AbstractCommand
end

struct OrCommands <: AbstractCommand
    a::AbstractCommand
    b::AbstractCommand
end

struct CommandPipe <: AbstractCommand
    a::AbstractCommand
    b::AbstractCommand
end

struct Redirect
    operator::String
    target::String
    function Redirect(operator, target)
        if operator ∉ ("<", "<<", ">", ">>", "2>", "&>", ">&", "2>&1")
            throw(ArgumentError("operator `$(operator)` is not supported!"))
        end
        return new(operator, target)
    end
end

struct CommandRedirect <: AbstractCommand
    command::AbstractCommand
    redirect::Redirect
end

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
