export interpret

"""
    interpret(command::Command)

Translate a `Command` object into a `Cmd` that can be executed.

# Examples
```jldoctest
julia> c = Command("ls", [LongFlag("all")], [], []);

julia> cmd = interpret(c)
`ls --all`

julia> typeof(cmd)
Cmd
```
"""
function interpret(command::Command)
    exec = [command.name]
    for parameter in values(command.parameters)
        if parameter isa ShortOption
            push!(exec, "-$(parameter.name)", string(parameter.value))
        elseif parameter isa LongOption
            push!(exec, "--$(parameter.name)=$(parameter.value)")
        elseif parameter isa ShortFlag
            push!(exec, "-$(parameter.name)")
        elseif parameter isa LongFlag
            push!(exec, "--$(parameter.name)")
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
julia> r = RedirectedCommand(Command("ls", [], [], []), "output.txt");

julia> cmd = interpret(r)
pipeline(`ls`, stdout>Base.FileRedirect("output.txt", false))

julia> typeof(cmd)
Base.CmdRedirect

julia> r = RedirectedCommand(".zshrc", Command("cat", [], [], []));

julia> cmd = interpret(r)
pipeline(`cat`, stdin<Base.FileRedirect(".zshrc", false))

julia> typeof(cmd)
Base.CmdRedirect
```
"""
function interpret(command::RedirectedCommand)
    if command.source isa String && command.destination isa AbstractCommand
        return pipeline(command.source, interpret(command.destination))
    elseif command.source isa AbstractCommand && command.destination isa String
        return pipeline(interpret(command.source), command.destination)
    else
        error("this should never happen!")
    end
end
"""
    interpret(commands::AndCommands)

Translate an `AndCommands` object into a `Base.AndCmds` that can be executed, considering the conjunction.

# Examples
```jldoctest
julia> c1 = Command("ls", [], [], []);

julia> c2 = Command("pwd", [], [], []);

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
julia> c1 = Command("ls", [], [], []);

julia> c2 = Command("pwd", [], [], []);

julia> oc = OrCommands(c1, c2);

julia> cmd = interpret(oc)
pipeline(`ls`, stdout=`pwd`)

julia> typeof(cmd)
Base.OrCmds
```
"""
interpret(commands::OrCommands) = Base.OrCmds(interpret(commands.a), interpret(commands.b))
