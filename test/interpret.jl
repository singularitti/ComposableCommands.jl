@testset "Test `interpret`ing commands" begin
    Base.:(==)(x::Base.OrCmds, y::Base.OrCmds) = x.a == y.a && x.b == y.b
    Base.:(==)(x::Base.CmdRedirect, y::Base.CmdRedirect) =
        x.cmd == y.cmd && x.handle == y.handle

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
    @testset "Test `OrCommands`" begin
        grep = Command("grep", [], [".bashrc"], [])
        pipe = OrCommands(ls, grep)
        cmd = interpret(pipe)
        @test cmd == pipeline(`ls -l -a --directory`, `grep .bashrc`)
        @test typeof(cmd) == Base.OrCmds
    end

    # ===== tree interface checks =====
    @testset "Tree interface" begin
        using AbstractTrees

        # reuse previously defined git/remote/show
        # directly constructing the iterator should succeed now
        nodes = collect(TreeIterator(git))
        @test length(nodes) == 2
        @test nodes[1] === git
        @test nodes[2] === remote

        # convenience wrapper exported by package
        @test allnodes(git) == nodes

        # iterable command (for loop) should produce same sequence
        collected = AbstractVector{Any}()
        for n in git
            push!(collected, n)
        end
        @test collected == nodes

        # iterating from a descendant is allowed too
        sub = remote
        subnodes = collect(TreeIterator(sub))
        @test subnodes == [sub, sh]
        @test allnodes(sub) == subnodes

        # complex nested/redirection example (ibrun -n $ncpu $VASP >& output.log)
        ncpu = 8
        vasp = Command("vasp", [], [], [])
        ibrun = Command("ibrun", [ShortOption("n", ncpu)], [], [vasp])
        redir = RedirectedCommand(ibrun, "output.log")
        @test allnodes(redir) == [redir, ibrun]
        io = IOBuffer(); print_tree(io, redir);
        str = String(take!(io))
        @test occursin("ibrun", str)
        @test occursin("-n 8", str)            # option shown
        @test occursin("vasp", str)           # argument shown
        @test occursin("> output.log", str)   # redirect label now shell-like

        # a pipe should render as a `|` node with both sides expanded
        left = Command("echo", [], ["hello"], [])
        right = Command("grep", [], ["h"], [])
        pipe = OrCommands(left, right)
        io2 = IOBuffer(); print_tree(io2, pipe); out2 = String(take!(io2))
        @test occursin("|", out2)                  # pipe symbol at root
        @test occursin("echo hello", out2)         # left child shown
        @test occursin("grep h", out2)            # right child shown

        io = IOBuffer()
        print_tree(io, git)
        str = String(take!(io))
        @test occursin("git", str)
        @test occursin("--verbose", str)        # flag shown inline
        @test occursin("└─ remote", str)

        # `AndCommands` should show shell '&&' operator
        and = AndCommands(git, ls)
        io_and = IOBuffer(); print_tree(io_and, and); out_and = String(take!(io_and))
        @test occursin("&&", out_and)
    end
end
