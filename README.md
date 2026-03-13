# ComposableCommands

| **Documentation** | [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://singularitti.github.io/ComposableCommands.jl/stable/) [![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://singularitti.github.io/ComposableCommands.jl/dev/)                                                                                                                                                                                                                                                                                                 |
| :---------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Build Status**  | [![Build Status](https://github.com/singularitti/ComposableCommands.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/singularitti/ComposableCommands.jl/actions/workflows/CI.yml?query=branch%3Amain) [![Build Status](https://ci.appveyor.com/api/projects/status/github/singularitti/ComposableCommands.jl?svg=true)](https://ci.appveyor.com/project/singularitti/ComposableCommands-jl)[![Build Status](https://api.cirrus-ci.com/github/singularitti/ComposableCommands.jl.svg)](https://cirrus-ci.com/github/singularitti/ComposableCommands.jl) |
|   **Coverage**    | [![Coverage](https://github.com/singularitti/ComposableCommands.jl/badges/main/coverage.svg)](https://github.com/singularitti/ComposableCommands.jl/commits/main) [![Coverage](https://codecov.io/gh/singularitti/ComposableCommands.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/singularitti/ComposableCommands.jl)                                                                                                                                                                                                                |
|    **Others**     | [![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle) [![License](https://img.shields.io/github/license/singularitti/ComposableCommands.jl)](https://github.com/singularitti/ComposableCommands.jl/blob/main/LICENSE)                                                                                                                                                                                                                                                   |

The code, which is [hosted on GitHub](https://github.com/singularitti/ComposableCommands.jl), is tested
using various continuous integration services for its validity.

This repository is created and maintained by
[@singularitti](https://github.com/singularitti), and contributions are highly welcome.

## Package features

- Abstract representation of command line commands, options, flags, and arguments
- Support for subcommands and command composition
- Redirection and pipe handling
- Intuitive API for building and interpreting commands

## Installation

The package can be installed with the Julia package manager.
From [the Julia REPL](https://docs.julialang.org/en/v1/stdlib/REPL/), type `]` to enter
the [Pkg mode](https://docs.julialang.org/en/v1/stdlib/REPL/#Pkg-mode) and run:

```julia-repl
pkg> add ComposableCommands
```

Or, equivalently, via [`Pkg.jl`](https://pkgdocs.julialang.org/v1/):

```julia
julia> import Pkg; Pkg.add("ComposableCommands")
```

## Documentation

- [**STABLE**](https://singularitti.github.io/ComposableCommands.jl/stable/) — **documentation of the most recently tagged version.**
- [**DEV**](https://singularitti.github.io/ComposableCommands.jl/dev/) — _documentation of the in-development version._

## Project status

The package is developed for and tested against Julia `v1.6` and above on Linux, macOS, and
Windows.

## Questions and contributions

You can post usage questions on
[our discussion page](https://github.com/singularitti/ComposableCommands.jl/discussions).

We welcome contributions, feature requests, and suggestions. If you encounter any problems,
please open an [issue](https://github.com/singularitti/ComposableCommands.jl/issues).
The [Contributing](@ref) page has
a few guidelines that should be followed when opening pull requests and contributing code.
