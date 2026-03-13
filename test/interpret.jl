@testset "Test `interpret`ing commands" begin
    @testset "Test `git` with multiple subcommands" begin
        verbose = LongFlag("verbose")
        no = ShortFlag("n")
        sh = Command("show", [no], ["origin"], [])
        remote = Command("remote", [verbose], [], [sh])
        global git = Command("git", [], [], [remote])
        cmd = interpret(git)
        @test cmd == `git remote --verbose show -n origin`
        @test typeof(cmd) == Cmd
    end
    @testset "Test `rm` command with flags" begin
        recursive = LongFlag("recursive")
        force = LongFlag("force")
        rm = Command("rm", [recursive, force], ["*.txt"], [])
        global rm_redirect = RedirectedCommand(rm, "logfile")
        cmd = interpret(rm_redirect)
        @test cmd == pipeline(`rm --recursive --force '*.txt'`, "logfile")
        @test typeof(cmd) == Base.CmdRedirect
    end
    @testset "Test `ls` command with flags" begin
        l = ShortFlag("l")
        a = ShortFlag("a")
        d = LongFlag("directory")
        global ls = Command("ls", [l, a, d], [], [])
        cmd = interpret(ls)
        @test cmd == `ls -l -a --directory`
        @test typeof(cmd) == Cmd
    end
    @testset "Test `RedirectedCommand` for `ls`" begin
        ls_out = RedirectedCommand(ls, "out.txt")
        cmd = interpret(ls_out)
        @test cmd == pipeline(`ls -l -a --directory`, "out.txt")
        @test typeof(cmd) == Base.CmdRedirect
    end
    @testset "Test `RedirectedCommand` with both input and output" begin
        ls_in = RedirectedCommand("in.txt", ls)
        cmd = interpret(ls_in)
        @test cmd == pipeline("in.txt", `ls -l -a --directory`)
        @test typeof(cmd) == Base.CmdRedirect
        ls_in_out = RedirectedCommand(ls_in, "out.txt")
        @test ls_in_out == ls("in.txt", "out.txt")
        cmd = interpret(ls_in_out)
        @test cmd == pipeline(`ls -l -a --directory`; stdin="in.txt", stdout="out.txt")
        @test typeof(cmd) == Base.CmdRedirect
    end
    @testset "Test `grep` command with an option and value" begin
        aft = LongOption("after-context", 3)
        grep = Command("grep", [aft], ["pattern", "file.txt"], [])
        cmd = interpret(grep)
        @test cmd == `grep --after-context=3 pattern file.txt`
        @test typeof(cmd) == Cmd
        @testset "Test `grep` command with a short option and value" begin
            aft = ShortOption("A", 3)
            grep = Command("grep", [aft], ["pattern", "file.txt"], [])
            cmd = interpret(grep)
            @test cmd == `grep -A 3 pattern file.txt`
            @test typeof(cmd) == Cmd
        end
    end
    @testset "Test `AndCommands`" begin
        and = AndCommands(git, rm_redirect)
        cmd = interpret(and)
        @test cmd ==
            `git remote --verbose show -n origin` &
              pipeline(`rm --recursive --force '*.txt'`, "logfile")
        @test typeof(cmd) == Base.AndCmds
    end
    @testset "Test `OrCommands`" begin
        or = OrCommands(git, ls)
        cmd = interpret(or)
        @test cmd == pipeline(interpret(git), interpret(ls))
        @test typeof(cmd) == Base.OrCmds
    end
    @testset "Test `OrCommands` as a pipe" begin
        grep = Command("grep", [], [".bashrc"], [])
        pipe = OrCommands(ls, grep)
        cmd = interpret(pipe)
        @test cmd == pipeline(`ls -l -a --directory`, `grep .bashrc`)
        @test typeof(cmd) == Base.OrCmds
    end
    @testset "Tree interface" begin
        verbose = LongFlag("verbose")
        no = ShortFlag("n")
        sh = Command("show", [no], ["origin"], [])
        remote = Command("remote", [verbose], [], [sh])
        git = Command("git", [], [], [remote])
        @test collectnodes(git) == [git, remote, sh]
        @testset "Test order" begin
            collected = []
            for n in git
                push!(collected, n)
            end
            @test collected == [git, remote, sh]
            @test collect(PreOrderDFS(git)) == [git, remote, sh]
            @test collect(PostOrderDFS(git)) == [sh, remote, git]
            @test collect(Leaves(git)) == [sh]
            @test collect(StatelessBFS(git)) == [git, remote, sh]
        end
        @testset "Test tree properties" begin
            @test getdescendant(git, (1, 1)) === sh
            @test AbstractTrees.parent(git, git) === nothing
            @test AbstractTrees.parent(git, remote) === git
            @test AbstractTrees.parent(git, sh) === remote
            @test treesize(git) == 3
            @test treebreadth(git) == 1
            @test treeheight(git) == 2
        end
        @testset "Test `ibrun` command" begin
            vasp = Command("vasp", [], [], [])
            ibrun = Command("ibrun", [ShortOption("n", 8)], [], [vasp])
            redir = RedirectedCommand(ibrun, "output.log")
            @test collectnodes(redir) == [redir, ibrun, vasp]
            @test collect(PostOrderDFS(redir)) == [vasp, ibrun, redir]
            @test collect(Leaves(redir)) == [vasp]
            @test collect(StatelessBFS(redir)) == [redir, ibrun, vasp]
            @test getdescendant(redir, (1, 1)) === vasp
            @test AbstractTrees.parent(redir, ibrun) === redir
            @test AbstractTrees.parent(redir, vasp) === ibrun
            @testset "Test buffer" begin
                io_redir = IOBuffer()
                print_tree(io_redir, redir)
                out_redir = String(take!(io_redir))
                @test occursin("> output.log", out_redir)
                @test occursin("ibrun -n 8", out_redir)
                @test occursin("vasp", out_redir)
            end
        end
        @testset "Test `OrCommands` as a pipe" begin
            left = Command("echo", [], ["hello"], [])
            right = Command("grep", [], ["h"], [])
            pipe = OrCommands(left, right)
            @test collectnodes(pipe) == [pipe, left, right]
            @test collect(PostOrderDFS(pipe)) == [left, right, pipe]
            @test collect(Leaves(pipe)) == [left, right]
            @test collect(StatelessBFS(pipe)) == [pipe, left, right]
            @testset "Test buffer" begin
                io_pipe = IOBuffer()
                print_tree(io_pipe, pipe)
                out_pipe = String(take!(io_pipe))
                @test occursin("|", out_pipe)
                @test occursin("echo hello", out_pipe)
                @test occursin("grep h", out_pipe)
            end
            io_and = IOBuffer()
            print_tree(io_and, AndCommands(left, right))
            @test occursin("&&", String(take!(io_and)))
        end
        io = IOBuffer()
        print_tree(io, git)
        out = String(take!(io))
        @test occursin("git", out)
        @test occursin("remote --verbose", out)
        @test occursin("show -n origin", out)
    end
end
