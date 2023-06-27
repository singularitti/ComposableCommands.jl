@testset "Test `interpret`ing commands" begin
    Base.:(==)(x::Base.OrCmds, y::Base.OrCmds) = x.a == y.a && x.b == y.b
    Base.:(==)(x::Base.CmdRedirect, y::Base.CmdRedirect) =
        x.cmd == y.cmd && x.handle == y.handle

    @testset "Test `git` with multiple subcommands" begin
        verbose = Flag("verbose", "v", "Be more verbose")
        no = Flag("", "n", "Do not query remotes")
        sh = Command("show", [no], [], ["origin"], [])
        remote = Command("remote", [verbose], [], [], [sh])
        global git = Command("git", [], [], [], [remote])
        cmd = interpret(git)
        @test cmd == `git remote --verbose show -n origin`
        @test typeof(cmd) == Cmd
    end
    @testset "Test `rm` command with flags" begin
        recursive = Flag(
            "recursive", "r", "remove directories and their contents recursively"
        )
        force = Flag("force", "f", "ignore nonexistent files and arguments, never prompt")
        # Create Command instance
        rm = Command("rm", [recursive, force], [], ["*.txt"], [])
        global rm_redirect = CommandRedirect(rm, Redirect(">", "logfile"))
        cmd = interpret(rm_redirect)
        @test cmd == pipeline(`rm --recursive --force '*.txt'`, "logfile")
        @test typeof(cmd) == Base.CmdRedirect
    end
    @testset "Test `ls` command with flags" begin
        l = Flag("long-format", "l", "use a long listing format")
        a = Flag("all", "a", "do not ignore entries starting with .")
        d = Flag("directory", "d", "list directories themselves, not their contents")
        global ls = Command("ls", [l, a, d], [], [], [])
        cmd = interpret(ls)
        @test cmd == `ls --long-format --all --directory`
        @test typeof(cmd) == Cmd
    end
    @testset "Test `CommandRedirect` for `ls`" begin
        ls_out = CommandRedirect(ls, Redirect(">", "out.txt"))
        cmd = interpret(ls_out)
        @test cmd == pipeline(`ls --long-format --all --directory`, "out.txt")
        @test typeof(cmd) == Base.CmdRedirect
    end
    @testset "Test `CommandRedirect` with both input and output" begin
        ls_in = CommandRedirect(ls, Redirect("<", "in.txt"))
        cmd = interpret(ls_in)
        @test cmd == pipeline("in.txt", `ls --long-format --all --directory`)
        @test typeof(cmd) == Base.CmdRedirect
        ls_in_out = CommandRedirect(ls_in, Redirect(">", "out.txt"))
        cmd = interpret(ls_in_out)
        @test cmd == pipeline(
            `ls --long-format --all --directory`; stdin="in.txt", stdout="out.txt"
        )
        @test typeof(cmd) == Base.CmdRedirect
    end
    @testset "Test `grep` command with an option and value" begin
        aft = Option("after-context", "A", "print NUM lines of trailing context", 3)
        grep = Command("grep", [], [aft], ["pattern", "file.txt"], [])
        cmd = interpret(grep)
        @test cmd == `grep --after-context=3 pattern file.txt`
        @test typeof(cmd) == Cmd
        @testset "Test `grep` command with a short option and value" begin
            aft = Option("", "A", "print NUM lines of trailing context", 3)
            grep = Command("grep", [], [aft], ["pattern", "file.txt"], [])
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
    @testset "Test `CommandPipe`" begin
        l = Flag("long-format", "l", "use a long listing format")
        ls = Command("ls", [l], [], [], [])
        grep = Command("grep", [], [], [".bashrc"], [])
        pipe = CommandPipe(ls, grep)
        cmd = interpret(pipe)
        @test cmd == pipeline(`ls --long-format`, `grep .bashrc`)
        @test typeof(cmd) == Base.OrCmds
    end
end