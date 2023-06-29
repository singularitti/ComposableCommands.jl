import Base: show

show(io::IO, command::AbstractCommand) = _show(io, command, 0)

function _show(io::IO, command::Command, indent=0)
    println(io, ' '^(indent * 2), "Command: ", command.name)
    if !isempty(command.parameters)
        println(io, ' '^(indent * 2), "Parameters:")
        for parameter in values(command.parameters)
            println(io, ' '^((indent + 1) * 2), parameter.name)
        end
    end
    if !isempty(command.arguments)
        println(io, ' '^(indent * 2), "Arguments:")
        for argument in command.arguments
            println(io, ' '^((indent + 1) * 2), argument)
        end
    end
    if !isempty(command.subcommands)
        println(io, ' '^(indent * 2), "Subcommands:")
        for subcommand in command.subcommands
            _show(io, subcommand, indent + 1)
        end
    end
end
function _show(io::IO, commands::AndCommands, indent=0)
    println(io, ' '^(indent * 2), "AndCommands:")
    println(io, ' '^((indent + 1) * 2), "Command 1:")
    _show(io, commands.a, indent + 2)
    println(io, ' '^((indent + 1) * 2), "Command 2:")
    return _show(io, commands.b, indent + 2)
end
function _show(io::IO, commands::OrCommands, indent=0)
    println(io, ' '^(indent * 2), "OrCommands:")
    println(io, ' '^((indent + 1) * 2), "Command 1:")
    _show(io, commands.a, indent + 2)
    println(io, ' '^((indent + 1) * 2), "Command 2:")
    return _show(io, commands.b, indent + 2)
end
function _show(io::IO, command::RedirectedCommand, indent=0)
    println(io, ' '^(indent * 2), "RedirectedCommand:")
    println(io, ' '^((indent + 1) * 2), "Source:")
    if command.source isa AbstractCommand
        _show(io, command.source, indent + 2)
    else  # command.source is a String (file)
        println(io, ' '^((indent + 2) * 2), command.source)
    end
    println(io, ' '^((indent + 1) * 2), "Destination:")
    if command.destination isa AbstractCommand
        _show(io, command.destination, indent + 2)
    else  # command.destination is a String (file)
        println(io, ' '^((indent + 2) * 2), command.destination)
    end
end
