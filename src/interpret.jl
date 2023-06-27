export interpret

"""
    interpret(command::Command)

Translate a `Command` object into a `Cmd` that can be executed.

# Examples
```jldoctest
julia> c = Command("ls", [Flag("all", "a", "list all files")], [], [], []);

julia> interpret(c)
`ls --all`
```
"""
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
"""
    interpret(command::RedirectedCommand)

Translate a `RedirectedCommand` object into a `Base.CmdRedirect` that can be executed, considering the redirection.

# Examples
```jldoctest
julia> c = Command("ls", [], [], [], []);

julia> r = Redirect(">", "output.txt");

julia> cr = RedirectedCommand(c, r);

julia> cmd = interpret(cr)
pipeline(`ls`, stdout>Base.FileRedirect("output.txt", false))

julia> typeof(cmd)
Base.CmdRedirect
```
"""
function interpret(command::RedirectedCommand)
    cmd = interpret(command.command)
    if command.redirect.operator in ("<", "<<")
        return pipeline(command.redirect.target, cmd)
    elseif command.redirect.operator in (">", ">>", "2>", "&>", ">&", "2>&1")
        return pipeline(cmd, command.redirect.target)
    else
        error("this should never happen!")
    end
end
"""
    interpret(commands::AndCommands)

Translate an `AndCommands` object into a `Base.AndCmds` that can be executed, considering the conjunction.

# Examples
```jldoctest
julia> c1 = Command("ls", [], [], [], []);

julia> c2 = Command("pwd", [], [], [], []);

julia> ac = AndCommands(c1, c2);

julia> cmd = interpret(ac)
`ls` & `pwd`

julia> typeof(cmd)
Base.AndCmds
```
"""
interpret(commands::AndCommands) =
    Base.AndCmds(interpret(commands.a), interpret(commands.b))
"""
    interpret(commands::OrCommands)

Translate an `OrCommands` object into a `Base.OrCmds` that can be executed, considering the disjunction.

# Examples
```jldoctest
julia> c1 = Command("ls", [], [], [], []);

julia> c2 = Command("pwd", [], [], [], []);

julia> oc = OrCommands(c1, c2);

julia> cmd = interpret(oc)
pipeline(`ls`, stdout=`pwd`)

julia> typeof(cmd)
Base.OrCmds
```
"""
interpret(commands::OrCommands) = Base.OrCmds(interpret(commands.a), interpret(commands.b))
