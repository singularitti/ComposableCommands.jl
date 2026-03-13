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

## Other examples

The following snippets show how you can build commands equivalent to common
`slurm` invocations and a `singularity` shell command.  The goal is to
construct the same argument lists programmatically.

```@repl
using ComposableCommands

srun1 = Command("srun",
                [ShortOption("N", 2), ShortOption("B", "4-4:2-2")],
                ["a.out"],
                [])  # srun -N2 -B 4-4:2-2 a.out
interpret(srun1)

server = Command("server", [ShortOption("n", 16), LongOption("mem-per-cpu", "1gb")], [], [])
client = Command("client", [], [], [])
srun2 = Command("srun",
                [ShortOption("n", 1), ShortOption("c", 8),
                 LongOption("mem-per-cpu", "2gb")],
                [],
                [server, client])  # srun -n1 -c8 --mem-per-cpu=2gb server : -n16 --mem-per-cpu=1gb client
interpret(srun2)

srun3 = Command("srun",
                [LongOption("nodes", [1, 5, 9, 13])],
                ["./test"],
                [])  # srun --nodes=1,5,9,13 ./test
interpret(srun3)

sinfo = Command("sinfo",
                [ShortFlag("N"),
                 ShortOption("O", ("nodelist", "partition", "cpusstate", "memory", "allocmem", "freemem"))],
                [],
                [])  # sinfo -N -O nodelist,partition,cpusstate,memory,allocmem,freemem
interpret(sinfo)

sbatch = Command("sbatch",
                 [LongOption("time", "25-00:00:00")],
                 ["my_short_script.sh"],
                 [])  # sbatch --time 25-00:00:00 my_short_script.sh
interpret(sbatch)

scontrol = Command("scontrol",
                    [],
                    ["update", "JobId=12345678", "TimeLimit=25-00:00:00"],
                    [])  # scontrol update JobId=12345678 TimeLimit=25-00:00:00
interpret(scontrol)

squeue = Command("squeue",
                  [ShortOption("o", "%.18i %.9P %.70j %.8u %.2t %.10M %.6D %4C %10m %15R %20p %7q %Z")],
                  [],
                  [])  # squeue -o "%.18i %.9P %.70j %.8u %.2t %.10M %.6D %4C %10m %15R %20p %7q %Z"
interpret(squeue)

srun_gpu = Command("srun",
                   [LongOption("gpus", 1), ShortOption("p", "gpu"),
                    LongFlag("pty")],
                   ["bash"],
                   [])  # srun --gpus 1 -p gpu --pty bash
interpret(srun_gpu)
```
