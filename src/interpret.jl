export interpret

function interpret(command::Command)
    exec = [command.name]
    for option in command.options
        if isempty(option.long_name)
            push!(exec, "-$(option.short_name)", string(option.value))
        else
            push!(exec, "--$(option.long_name)=$(option.value)")
        end
    end
    for flag in command.flags
        if isempty(flag.long_name)
            push!(exec, "-$(flag.short_name)")
        else
            push!(exec, "--$(flag.long_name)")
        end
    end
    for arg in command.arguments
        push!(exec, arg)
    end
    for subcommand in command.subcommands  # Recursively process subcommands
        sub_exec = interpret(subcommand)
        append!(exec, sub_exec.exec)
    end
    return Cmd(exec)
end
function interpret(command::CommandRedirect)
    cmd = interpret(command.command)
    if command.redirect.operator in ("<", "<<")
        return pipeline(command.redirect.target, cmd)
    elseif command.redirect.operator in (">", ">>", "2>", "&>", ">&", "2>&1")
        return pipeline(cmd, command.redirect.target)
    else
        error("this should never happen!")
    end
end
interpret(commands::CommandPipe) = pipeline(interpret(commands.a), interpret(commands.b))
interpret(commands::AndCommands) =
    Base.AndCmds(interpret(commands.a), interpret(commands.b))
interpret(commands::OrCommands) = Base.OrCmds(interpret(commands.a), interpret(commands.b))
