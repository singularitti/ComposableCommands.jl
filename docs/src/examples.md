# Examples

```@contents
Pages = ["examples.md"]
Depth = 2:2
```

## Building a command tree

```@repl
using ComposableCommands

show_cmd = Command("show", [ShortFlag("n")], ["origin"], [])
remote_cmd = Command("remote", [LongFlag("verbose")], [], [show_cmd])
git_cmd = Command("git", [], [], [remote_cmd])

git_cmd
interpret(git_cmd)
```

## Redirecting input and output

```@repl
using ComposableCommands

sort_cmd = Command("sort", [ShortFlag("n")], [], [])
redirected_in = RedirectedCommand("numbers.txt", sort_cmd)
redirected_out = RedirectedCommand(sort_cmd, "sorted.txt")

interpret(redirected_in)
interpret(redirected_out)
```

## Pipelining and parallel composition

```@repl
using ComposableCommands

cut_cmd = Command("cut", [ShortOption("d", ":"), ShortOption("f", 3)], ["/etc/passwd"], [])
sort_cmd = Command("sort", [ShortFlag("n")], [], [])
tail_cmd = Command("tail", [ShortOption("n", 5)], [], [])
pipeline_cmd = OrCommands(OrCommands(cut_cmd, sort_cmd), tail_cmd)

left_echo = Command("echo", [], ["hello"], [])
right_echo = Command("echo", [], ["world"], [])
parallel_cmd = AndCommands(left_echo, right_echo)

interpret(pipeline_cmd)
interpret(parallel_cmd)
```

## Traversing and printing

```@repl
using ComposableCommands
using AbstractTrees

vasp_cmd = Command("vasp", [], [], [])
ibrun_cmd = Command("ibrun", [ShortOption("n", 8)], [], [vasp_cmd])
job_cmd = RedirectedCommand(ibrun_cmd, "output.log")

collectnodes(job_cmd)
print_tree(job_cmd)
```
