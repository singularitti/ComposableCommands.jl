module CommandComposer

using OrderedCollections: OrderedDict

export ShortFlag,
    LongFlag, ShortOption, LongOption, AndCommands, OrCommands, RedirectedCommand, Command

abstract type CommandParameter end
abstract type Flag <: CommandParameter end
"""
    ShortFlag(name::String)

Represent a short flag associated with a command.
"""
struct ShortFlag <: Flag
    name::String
end
"""
    LongFlag(name::String)

Represent a long flag associated with a command.
"""
struct LongFlag <: Flag
    name::String
end
abstract type Option <: CommandParameter end
"""
    ShortOption(name::String, value)

Represent a short option associated with a command.
"""
struct ShortOption <: Option
    name::String
    value
end
"""
    LongOption(name::String, value)

Represent a long option associated with a command.
"""
struct LongOption <: Option
    name::String
    value
end

abstract type AbstractCommand end

"""
    AndCommands(a::AbstractCommand, b::AbstractCommand)

Represent a conjunction of two commands (i.e., both commands are executed).
"""
struct AndCommands <: AbstractCommand
    a::AbstractCommand
    b::AbstractCommand
end

"""
    OrCommands(a::AbstractCommand, b::AbstractCommand)

Represent a disjunction of two commands (i.e., either command is executed).
"""
struct OrCommands <: AbstractCommand
    a::AbstractCommand
    b::AbstractCommand
end

"""
    RedirectedCommand(source, destination)

Wrap an `AbstractCommand` and a file (`String`).

It allows output redirection from a command to a file or input redirection from a
file to a command. The redirection is specified by the `RedirectedCommand`'s
`source` and `destination` parameters.

# Arguments
- `source`: The source from which to redirect. If `source` is a `String`, it represents the
  filename of the file from which to read. If `source` is a subtype of `AbstractCommand`, it
  represents the command whose output is to be redirected.
- `destination`: The destination to which to redirect. If `destination` is a `String`, it
  represents the filename of the file to which to write. If `destination` is a subtype of
  `AbstractCommand`, it represents the command that takes the redirected output as input.
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
    Command(name, parameters, arguments, subcommands)

Represent a command to be executed, with associated flags, options, arguments, and subcommands.

# Arguments
- `name::String`: the name of the command.
- `parameters`: an iterable of flags and options.
- `arguments::Vector{String}`: any arguments to the command.
- `subcommands::Vector{AbstractCommand}`: any subcommands to be executed in conjunction with the main command.
"""
struct Command <: AbstractCommand
    name::String
    parameters::OrderedDict{String,CommandParameter}
    arguments::Vector{String}
    subcommands::Vector{AbstractCommand}
    function Command(name, parameters, arguments, subcommands)
        if parameters isa AbstractDict
            return new(name, parameters, arguments, subcommands)
        else
            dict = OrderedDict{String,CommandParameter}()
            for parameter in parameters
                if haskey(dict, parameter.name)
                    @warn "duplicate parameter found: $(parameter.name)!"
                end
                dict[parameter.name] = parameter
            end
            return new(name, dict, arguments, subcommands)
        end
    end
end
# See https://github.com/JuliaLang/julia/blob/27c6d97/base/cmd.jl#L381-L395
function (command::Command)(stdin=nothing, stdout=nothing)
    if stdin !== nothing
        command = RedirectedCommand(stdin, command)
    end
    if stdout !== nothing
        command = RedirectedCommand(command, stdout)
    end
    return command
end

include("show.jl")
include("interpret.jl")

end
