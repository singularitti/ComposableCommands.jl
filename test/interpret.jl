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
end
