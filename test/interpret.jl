@testset "Test `interpret`ing commands" begin
    Base.:(==)(x::Base.OrCmds, y::Base.OrCmds) = x.a == y.a && x.b == y.b
    Base.:(==)(x::Base.CmdRedirect, y::Base.CmdRedirect) =
        x.cmd == y.cmd && x.handle == y.handle

    @testset "Test structural equality" begin
        show_a = Command("show", [ShortFlag("n")], ["origin"], [])
        show_b = Command("show", [ShortFlag("n")], ["origin"], [])
        remote_a = Command("remote", [LongFlag("verbose")], [], [show_a])
        remote_b = Command("remote", [LongFlag("verbose")], [], [show_b])
        git_a = Command("git", [], [], [remote_a])
        git_b = Command("git", [], [], [remote_b])

        @test ShortFlag("n") == ShortFlag("n")
        @test LongOption("after-context", 3) == LongOption("after-context", 3)
        @test show_a == show_b
        @test remote_a == remote_b
        @test git_a == git_b
        @test RedirectedCommand(git_a, "log.txt") == RedirectedCommand(git_b, "log.txt")
        @test AndCommands(git_a, show_a) == AndCommands(git_b, show_b)
        @test OrCommands(git_a, show_a) == OrCommands(git_b, show_b)
    end

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
        using AbstractTrees

        AbstractCommandT = ComposableCommands.AbstractCommand

        verbose = LongFlag("verbose")
        no = ShortFlag("n")
        sh = Command("show", [no], ["origin"], [])
        remote = Command("remote", [verbose], [], [sh])
        git = Command("git", [], [], [remote])

        nodes = collect(TreeIterator(git))
        @test nodes == AbstractCommandT[git, remote, sh]
        @test collectnodes(git) == nodes
        @test collectnodes(git) == nodes

        collected = AbstractCommandT[]
        for n in git
            push!(collected, n)
        end
        @test collected == nodes

        @test collect(PreOrderDFS(git)) == AbstractCommandT[git, remote, sh]
        @test collect(PostOrderDFS(git)) == AbstractCommandT[sh, remote, git]
        @test collect(Leaves(git)) == AbstractCommandT[sh]
        @test collect(StatelessBFS(git)) == AbstractCommandT[git, remote, sh]
        @test getdescendant(git, (1, 1)) === sh
        @test AbstractTrees.parent(git, git) === nothing
        @test AbstractTrees.parent(git, remote) === git
        @test AbstractTrees.parent(git, sh) === remote
        @test treesize(git) == 3
        @test treebreadth(git) == 1
        @test treeheight(git) == 2

        vasp = Command("vasp", [], [], [])
        ibrun = Command("ibrun", [ShortOption("n", 8)], [], [vasp])
        redir = RedirectedCommand(ibrun, "output.log")
        @test collectnodes(redir) == AbstractCommandT[redir, ibrun, vasp]
        @test collectnodes(redir) == AbstractCommandT[redir, ibrun, vasp]
        @test collect(PostOrderDFS(redir)) == AbstractCommandT[vasp, ibrun, redir]
        @test collect(Leaves(redir)) == AbstractCommandT[vasp]
        @test collect(StatelessBFS(redir)) == AbstractCommandT[redir, ibrun, vasp]
        @test getdescendant(redir, (1, 1)) === vasp
        @test AbstractTrees.parent(redir, ibrun) === redir
        @test AbstractTrees.parent(redir, vasp) === ibrun

        left = Command("echo", [], ["hello"], [])
        right = Command("grep", [], ["h"], [])
        pipe = OrCommands(left, right)
        @test collectnodes(pipe) == AbstractCommandT[pipe, left, right]
        @test collect(PostOrderDFS(pipe)) == AbstractCommandT[left, right, pipe]
        @test collect(Leaves(pipe)) == AbstractCommandT[left, right]
        @test collect(StatelessBFS(pipe)) == AbstractCommandT[pipe, left, right]

        io = IOBuffer()
        print_tree(io, git)
        out = String(take!(io))
        @test occursin("git", out)
        @test occursin("remote --verbose", out)
        @test occursin("show -n origin", out)

        io_redir = IOBuffer()
        print_tree(io_redir, redir)
        out_redir = String(take!(io_redir))
        @test occursin("> output.log", out_redir)
        @test occursin("ibrun -n 8", out_redir)
        @test occursin("vasp", out_redir)

        io_pipe = IOBuffer()
        print_tree(io_pipe, pipe)
        out_pipe = String(take!(io_pipe))
        @test occursin("|", out_pipe)
        @test occursin("echo hello", out_pipe)
        @test occursin("grep h", out_pipe)

        io_and = IOBuffer()
        print_tree(io_and, AndCommands(left, right))
        @test occursin("&&", String(take!(io_and)))
    end
end
