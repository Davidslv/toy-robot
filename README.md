# Toy Robot Simulator

A Ruby command-line application that moves a toy robot around a table
(5 x 5 by default).
It reads `PLACE`, `MOVE`, `LEFT`, `RIGHT` and `REPORT` commands from a file or
standard input. The robot never falls off the table.

The full brief is in [docs/brief.md](docs/brief.md).

```
$ bin/toy_robot examples/c_complex_sequence.txt
3,3,NORTH
```

## Contents

- [Setup](#setup)
- [Running](#running)
- [Testing](#testing)
- [Approach](#approach)
- [Assumptions](#assumptions)
- [Future improvements](#future-improvements)

## Setup

Requires Ruby 4.0.7 (see [.ruby-version](.ruby-version)). CI also runs on Ruby 3.4.
There are no runtime gems. Bundler installs only the development and test tools.

```bash
# with rbenv; any Ruby version manager works
brew install rbenv ruby-build
rbenv install          # reads .ruby-version

bundle install
```

## Running

Pass a file, or pipe commands on standard input:

```bash
bin/toy_robot examples/a_basic_movement.txt

bin/toy_robot < examples/b_rotation.txt

printf 'PLACE 0,0,NORTH\nMOVE\nREPORT\n' | bin/toy_robot

bin/toy_robot --size 7x3 examples/a_basic_movement.txt

bin/toy_robot --help
```

### Options

| Option | Effect |
| --- | --- |
| `-s`, `--size WIDTHxHEIGHT` | Table size. Defaults to `5x5`. Both numbers must be at least 1. |
| `-h`, `--help` | Show usage. |

Options can come before or after the file. A bad option or size prints the
reason and the usage on stderr, and exits with status 1.

Each `REPORT` prints one line, `X,Y,F`. A missing file prints an error on
stderr and exits with status 1.

With no file, it reads what you type, one command per line. There is no
prompt. Press Ctrl-D to finish (exit 0) or Ctrl-C to stop (exit 130, no
stack trace).

### Commands

| Command       | Effect                                                                 |
| ------------- | ---------------------------------------------------------------------- |
| `PLACE X,Y,F` | Put the robot at X,Y facing `NORTH`, `SOUTH`, `EAST` or `WEST`.        |
| `MOVE`        | Move one unit forward.                                                 |
| `LEFT`        | Turn 90 degrees counter-clockwise.                                     |
| `RIGHT`       | Turn 90 degrees clockwise.                                             |
| `REPORT`      | Print `X,Y,F`.                                                         |

`(0,0)` is the SOUTH-WEST corner. Commands before the first valid `PLACE` are
discarded. A `PLACE` or `MOVE` that would put the robot off the table is
ignored. Lines that are not commands are skipped.

## Testing

```bash
bundle exec rspec       # 137 examples, 100% line coverage enforced
bundle exec rubocop     # lint
bundle exec rubycritic  # optional quality report, opens in a browser
```

The suite has two layers:

- **Unit specs** (`spec/lib/`): one file per class. They were written before
  the code, one class at a time (see the commit history).
- **Acceptance specs** (`spec/acceptance/examples_spec.rb`): run the real
  `bin/toy_robot` as a separate process for every file in
  [examples/](examples), passing it both as a file argument and on standard
  input. They compare stdout with the matching `.expected` file.

### Test data

[examples/](examples) holds the test data and expected results. Each case is a
`NAME.txt` of commands and a `NAME.expected` with the exact output.

| Example | Proves |
| --- | --- |
| `a_basic_movement` | Scenario A from the brief |
| `b_rotation` | Scenario B from the brief |
| `c_complex_sequence` | Scenario C from the brief |
| `d_commands_before_place_are_discarded` | Nothing runs until a valid PLACE |
| `e_off_table_place_is_ignored` | PLACE off any edge is ignored, before and after placement |
| `f_cannot_fall_off_any_edge` | MOVE off each of the four edges is ignored |
| `g_walk_the_perimeter` | Walking the full edge, bumping into every corner |
| `h_place_again_moves_the_robot` | A second PLACE moves the robot |
| `i_invalid_lines_are_skipped` | Blank, unknown, lower-case and malformed lines are skipped |
| `j_never_placed_prints_nothing` | No PLACE means no output |

To add a case, add a new pair of files. The acceptance spec picks it up
automatically.

CI runs RuboCop and RSpec on Ruby 4.0 and 3.4, on Ubuntu and macOS
(`.github/workflows/test.yml`).

## Approach

### How a line flows through the code

```
bin/toy_robot ─▶ CLI ─▶ Simulator.run(lines)
                           │
                           │  for each line
                           ▼
                        Parser.parse(line) ─▶ Command or nil
                           │
                           ▼
                        command.call(robot, table:, output:) ─▶ next robot
```

### Classes

All code is under `lib/toy_robot/`, one concept per file.

| Class | Responsibility |
| --- | --- |
| `Direction` | The four headings, their step offsets, and left/right turns. |
| `Position` | An (x, y) point. `step(direction)` returns the neighbour. |
| `Robot` | Position plus direction. `move`, `turn_left`, `turn_right` return a new robot. |
| `Table` | Its size, and `contains?(position)`. The only class that knows the edges. |
| `Commands::*` | One class per instruction: `Place`, `Move`, `Left`, `Right`, `Report`. |
| `Parser` | Text to command object. Returns nil for anything it does not understand. |
| `Simulator` | Runs lines in order and holds the "discard until placed" rule. |
| `CLI` | Parses options (`--size`, `--help`), chooses file or stdin, reports errors, returns an exit status. |

### Design patterns, and why

- **Command pattern.** Each instruction is an object with
  `call(robot, table:, output:) -> robot`. The brief is a command set, so the
  code has the same shape. Each command is tested on its own. A new command is
  one new class plus one parser entry, with no edits to existing commands.

- **Immutable value objects** (`Direction`, `Position`, `Robot`, built with
  Ruby's `Data`). Every action returns a new object. `MOVE` builds the robot it
  would become, asks the table about it, and keeps the old one if the answer is
  no. That is the whole "ignore a move that would fall" rule: no undo and no
  half-updated state.

- **Single owner per rule.** The table edges live only in `Table`. Rotation
  order lives only in `Direction`. "Discard until placed" lives only in
  `Simulator`. Text syntax lives only in `Parser`. To change a rule, you edit
  one file.

- **Dependency injection.** The simulator receives its output, table and
  parser. The CLI receives argv, stdin, stdout and stderr. The specs run the
  whole application in memory with `StringIO` and try other table sizes
  without stubbing globals.

- **Ask the command, not its class.** The simulator checks
  `command.requires_robot?` and never checks `is_a?(Place)`. Any future command
  that can place the robot needs no simulator change.

How this maps to SOLID:

- **S:** each class above has one reason to change.
- **O:** new commands extend the system without editing existing ones.
- **L:** every command is interchangeable behind the same `call` signature.
- **I:** commands take keyword arguments and ignore the ones they do not need
  (`**`), so `Left` never has to mention the table.
- **D:** `Report` writes to whatever output it is given, never to `$stdout`
  directly.

### Patterns deliberately not used

- **State pattern for "not yet placed".** There are two states and one rule.
  A nil check in `Simulator` is easier to read than two state classes.
- **Singletons and global configuration.** The table size is a constructor
  argument, so tests can change it without touching globals.

### Code quality notes

RuboCop reports no offenses. RubyCritic rates every file A. Reek raises a few
warnings that come from deliberate choices:

- *UtilityFunction* on the commands: stateless command objects are the point
  of the pattern.
- *UnusedParameters* on `Command#call`: it is the abstract signature, and it
  raises.
- *FeatureEnvy* on `Parser#parse_place`: it reads fields from a regex match,
  which is its job.

### Working method

The work was done test-first, one class per commit, with each commit message
explaining the decision behind it. `git log --reverse` reads as a narrative of
how the design was built.

## Assumptions

- **Table size defaults to 5 x 5.** The brief we received is pages 2 and 3 of
  3. Page 1, which probably states the size, was not in the PDF. 5 x 5 is the
  traditional size for this exercise, and all three example scenarios fit
  inside it. Any other size can be passed with `--size WIDTHxHEIGHT`.
- **Invalid input is ignored silently**, matching "any move that would cause
  the robot to fall must be ignored" and "discard all commands" in the brief.
  Nothing is written to stderr for skipped lines, so stdout and stderr stay
  clean for scripts.
- **Keywords are upper case only** (`move` is rejected), as in the brief.
  Spaces around the line and after the commas in `PLACE` are tolerated.
- **Output format is `X,Y,F`**, exactly as in the brief's examples.
- **A valid `PLACE` on a placed robot moves it**, as the brief allows. An
  invalid one leaves the robot where it was.

## Future improvements

- **Confirm the default table size** against page 1 of the brief.
- **Optional diagnostics.** A `--verbose` flag that writes skipped lines and
  ignored moves to stderr, with line numbers, to help someone debug a command
  file. Keep stdout unchanged.
- **Interactive mode.** When stdin is a terminal, show a prompt and print
  REPORT results as they happen. Today it works line by line already, but with
  no prompt.
- **Property-based tests** (for example with `rantly`): generate random
  command sequences and assert the robot is always on the table and that four
  LEFTs or four RIGHTs are a no-op.
- **Mutation testing** (`mutant`) to check that the specs constrain every
  branch, beyond the 100% line coverage they already reach.
- **Package as a gem** with an executable, if it needed to be installed rather
  than run from the repository.
- **Obstacles or several robots**, if the exercise grew. `Table#contains?`
  would become the place to ask "is this square free?", and the Simulator would
  hold several robots. The command interface would not need to change.

## Project layout

```
bin/toy_robot              executable
lib/toy_robot.rb           requires every file below
lib/toy_robot/             one class per file
lib/toy_robot/commands/    one class per instruction
spec/lib/                  unit specs, mirroring lib/
spec/acceptance/           runs bin/toy_robot against examples/
spec/support/              shared spec helpers
examples/                  test data: NAME.txt + NAME.expected
docs/brief.md              the assessment brief, verbatim
```
