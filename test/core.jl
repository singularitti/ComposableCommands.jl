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
