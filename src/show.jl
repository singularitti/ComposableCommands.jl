import Base: show

show(io::IO, command::AbstractCommand) = _show(io, command, 0)

function _show(io::IO, command::Command, indent=0)
    println(io, ' '^(indent * 2), "Command: ", command.name)
    if !isempty(command.flags)
        println(io, ' '^(indent * 2), "Flags:")
        for flag in command.flags
            println(io, ' '^((indent + 1) * 2), flag.long_name, "/", flag.short_name)
        end
    end
    if !isempty(command.options)
        println(io, ' '^(indent * 2), "Options:")
        for option in command.options
            println(io, ' '^((indent + 1) * 2), option.long_name, "/", option.short_name)
        end
    end
    if !isempty(command.subcommands)
        println(io, ' '^(indent * 2), "Subcommands:")
        for subcommand in command.subcommands
            _show(io, subcommand, indent + 1)
        end
    end
    if !isempty(command.arguments)
        println(io, ' '^(indent * 2), "Arguments:")
        for argument in command.arguments
            println(io, ' '^((indent + 1) * 2), argument)
        end
    end
end
function _show(io::IO, commands::CommandPipe, indent=0)
    println(io, ' '^(indent * 2), "CommandPipe:")
    println(io, ' '^((indent + 1) * 2), "Command 1:")
    _show(io, commands.a, indent + 2)
    println(io, ' '^((indent + 1) * 2), "Command 2:")
    return _show(io, commands.b, indent + 2)
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
function _show(io::IO, command::CommandRedirect, indent=0)
    println(io, ' '^(indent * 2), "CommandRedirect:")
    println(io, ' '^((indent + 1) * 2), "Command:")
    _show(io, command.command, indent + 2)
    println(io, ' '^((indent + 1) * 2), "Redirect:")
    println(io, ' '^((indent + 2) * 2), "Operator: ", command.redirect.operator)
    return println(io, ' '^((indent + 2) * 2), "Target: ", command.redirect.target)
end
