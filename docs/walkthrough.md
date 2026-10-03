# Walkthrough

A guided tour of the code, one topic at a time.

> **How to read this**
> - Every topic has the same layout: **TL;DR → File → Code → How → Why → Watch out**.
> - Read the **TL;DR** lines only for a 2-minute overview.
> - Stop after any topic. Tick it off. Come back later.
> - Unsure what some Ruby syntax means? See the [Ruby cheat sheet](#ruby-cheat-sheet) at the bottom.
> - Code here is **shortened** to fit (one-line methods, no comments). The real files use full `def … end` and say the same thing.

---

## Map

- [ ] [1. The rules](#1-the-rules): what the brief requires, and where each rule lives
- [ ] [2. Direction](#2-direction): the four headings and turning
- [ ] [3. Position](#3-position): an (x, y) point that can step
- [ ] [4. Table](#4-table): the only class that knows the edges
- [ ] [5. Robot](#5-robot): position + direction, never changed in place
- [ ] [6. Commands](#6-commands): one class per instruction
- [ ] [7. Parser](#7-parser): text → command object
- [ ] [8. Simulator](#8-simulator): the loop, and "discard until placed"
- [ ] [9. CLI](#9-cli): file or stdin, `--size`, errors, Ctrl-C
- [ ] [10. Tests](#10-tests): unit, acceptance, TDD
- [ ] [11. Tooling and CI](#11-tooling-and-ci): RuboCop, coverage, GitHub Actions
- [ ] [12. Trade-offs and next steps](#12-trade-offs-and-next-steps)

### The whole program in one picture

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

---

## 1. The rules

**TL;DR:** Five rules from the brief. **Each lives in exactly one place.**

| Rule | Where |
| --- | --- |
| Robot must not fall off, including on PLACE | `Table#contains?` |
| A move that would fall is ignored | `Commands::Move` |
| Discard everything until a valid PLACE | `Simulator#execute` |
| Origin (0,0) is SOUTH-WEST | `Direction` (NORTH = y+1, EAST = x+1) |
| REPORT prints X,Y,F | `Robot#to_s`, written by `Commands::Report` |

**Why:** change a rule → edit one file.

---

## 2. Direction

**TL;DR:** A heading knows its one-step offset and its left/right neighbours.

**File:** `lib/toy_robot/direction.rb`

**Code:**

```ruby
Direction = Data.define(:name, :dx, :dy)

class Direction
  NORTH = new(name: 'NORTH', dx: 0, dy: 1)
  EAST  = new(name: 'EAST',  dx: 1, dy: 0)
  SOUTH = new(name: 'SOUTH', dx: 0, dy: -1)
  WEST  = new(name: 'WEST',  dx: -1, dy: 0)

  CLOCKWISE = [NORTH, EAST, SOUTH, WEST].freeze

  def left  = turn(-1)
  def right = turn(1)

  def turn(quarter_turns)
    CLOCKWISE[(CLOCKWISE.index(self) + quarter_turns) % CLOCKWISE.size]
  end
end
```

**How:**
1. `dx`/`dy` = how x and y change for one step forward.
2. RIGHT = one place forward in `CLOCKWISE`. LEFT = one place back.
3. `%` wraps around: WEST → right → NORTH.
4. `Direction.find('UP')` returns `nil`, which the parser uses to reject bad headings.

**Why:**
- **One list replaces an 8-branch `case`.** There's less to get wrong.
- Only this file knows which way is "up".

**Watch out:**
- `Data.define` is explained in the [cheat sheet](#datadefine).
- The class is written twice (`Direction = Data.define…` then `class Direction`). Putting methods inside a `Data.define` block made `CLOCKWISE` look in the wrong place (`ToyRobot::CLOCKWISE`). Reopening the class fixes the lookup.

---

## 3. Position

**TL;DR:** An (x, y) point. `step(direction)` gives the next point. **It never checks the edges.**

**File:** `lib/toy_robot/position.rb`

**Code:**

```ruby
Position = Data.define(:x, :y)

class Position
  def step(direction)
    with(x: x + direction.dx, y: y + direction.dy)
  end

  def to_s
    "#{x},#{y}"
  end
end
```

**How:**

```ruby
here = Position.new(x: 2, y: 3)
here.step(Direction::NORTH)   # => (2,4)
here                          # => still (2,3)
Position.new(x: 0, y: 0).step(Direction::SOUTH)   # => (0,-1), no error
```

**Why:**
- Position does the arithmetic. **Table makes the decision.**
- If both checked edges, the rule would live in two places and could drift apart.

---

## 4. Table

**TL;DR:** Knows its size. Answers one question: **is this position on me?**

**File:** `lib/toy_robot/table.rb`

**Code:**

```ruby
class Table
  DEFAULT_SIZE = 5

  def initialize(width: DEFAULT_SIZE, height: DEFAULT_SIZE)
    raise ArgumentError, "width must be at least 1, got #{width}" if width < 1
    raise ArgumentError, "height must be at least 1, got #{height}" if height < 1

    @x_range = 0...width
    @y_range = 0...height
    freeze
  end

  def contains?(position)
    @x_range.cover?(position.x) && @y_range.cover?(position.y)
  end
end
```

**How:**
1. `0...5` (three dots) = 0, 1, 2, 3, 4. **5 is not included.**
2. `cover?` = "is this number inside the range?"
3. A 0-wide table raises straight away, with a clear message.
4. `freeze` = cannot be changed after it's built.

**Why:**
- **The only place that knows the edges.** PLACE and MOVE both ask it.
- Obstacles later? Change `contains?`, nothing else.

**Watch out:**
- 5 x 5 is an assumption. Page 1 of the brief was missing. Override with `--size 7x3`.

---

## 5. Robot

**TL;DR:** Position + direction. **Every action returns a new robot.** The old one is never touched.

**File:** `lib/toy_robot/robot.rb`

**Code:**

```ruby
Robot = Data.define(:position, :direction)

class Robot
  def move       = with(position: position.step(direction))
  def turn_left  = with(direction: direction.left)
  def turn_right = with(direction: direction.right)
  def to_s       = "#{position},#{direction}"     # "1,2,EAST"
end
```

**How:**

```ruby
robot = Robot.new(position: Position.new(x: 1, y: 2), direction: Direction::EAST)
moved = robot.move
moved.to_s   # => "2,2,EAST"
robot.to_s   # => "1,2,EAST"  ← unchanged
```

**Why:**
- **Check first, then decide.** MOVE builds the new robot, asks the table, then keeps whichever robot is safe.
- No undo logic, and no chance of a half-moved robot.
- The robot doesn't know about the table. The commands bring them together.

---

## 6. Commands

**TL;DR:** **One small class per instruction** (the Command pattern). All share one method:

```ruby
call(robot, table:, output:)   # → the robot as it should be afterwards
```

**Files:** `lib/toy_robot/commands/` with `command.rb`, `place.rb`, `move.rb`, `left.rb`, `right.rb`, `report.rb`

### 6a. The base class

```ruby
class Command
  def requires_robot? = true          # can only run once the robot is placed
  def call(_robot, table:, output:)   # each command replaces this
    raise NotImplementedError, "#{self.class}#call is not implemented"
  end
end
```

- `requires_robot?` is **true for all except PLACE**. The simulator reads it.
- A new command that forgets `call` fails loudly.

### 6b. PLACE and MOVE (the two that ask the table)

```ruby
class Place < Command
  def requires_robot? = false
  def call(robot, table:, **)
    return robot unless table.contains?(position)   # off table → nothing changes
    Robot.new(position: position, direction: direction)
  end
end

class Move < Command
  def call(robot, table:, **)
    moved = robot.move
    table.contains?(moved.position) ? moved : robot
  end
end
```

### 6c. LEFT, RIGHT, REPORT (never ask the table)

```ruby
class Left   < Command; def call(robot, **) = robot.turn_left;  end
class Right  < Command; def call(robot, **) = robot.turn_right; end
class Report < Command
  def call(robot, output:, **)
    output.puts(robot)   # prints "3,3,NORTH"
    robot                # nothing changed → same robot back
  end
end
```

### ⭐ The key idea: why return the original robot?

The simulator does this, every time, for every command:

```ruby
@robot = command.call(robot, ...)
```

It **always replaces the robot with whatever comes back.** So:

| The command returns… | Result |
| --- | --- |
| a new robot | robot changes |
| the robot it was given | nothing changes = **"ignored"** |
| `nil` (wrong!) | robot is wiped, everything is discarded until the next PLACE |

Trace, robot on the top edge facing NORTH:

```
@robot = (0,4,NORTH)
MOVE:  moved = (0,5) → off table → return robot
@robot = (0,4,NORTH)   ← unchanged, move ignored
```

**Where this idea comes from:** it's a *reducer* or *fold*: state in, new state out. It's the same shape as Redux in JavaScript, and as `commands.reduce(nil) { |robot, cmd| cmd.call(robot, ...) }`.

### Why objects (`Report.new.call`) and not class methods (`Report.call`)?

- **PLACE has to carry data** (1, 2, EAST) from parse time to run time, so it must be an object.
- **The other four are objects too, so all five look identical** to the simulator: `command.call(...)`.
- With class methods, PLACE would need extra arguments, and the simulator would need an `if` per command type.
- In the real flow the two steps are far apart: the **Parser** does `.new`, the **Simulator** does `.call`.

**Summary table:**

| Command | Asks table? | Needs robot first? | Returns |
| --- | --- | --- | --- |
| PLACE | yes | no | new robot, or old one if off table |
| MOVE | yes | yes | moved robot, or old one if it would fall |
| LEFT / RIGHT | no | yes | turned robot |
| REPORT | no | yes | same robot (prints it) |

**Watch out:**
- `**` = "accept other keyword arguments and ignore them". It lets LEFT skip `table:` and `output:`.
- REPORT writes to `output`, **never straight to the terminal**. That's how tests capture it with `StringIO`.

---

## 7. Parser

**TL;DR:** Text → command object, or `nil` if not understood. **It checks shape only, not the edges.**

**File:** `lib/toy_robot/parser.rb`

**Code (simple commands):**

```ruby
SIMPLE_COMMANDS = {
  'MOVE' => Commands::Move, 'LEFT' => Commands::Left,
  'RIGHT' => Commands::Right, 'REPORT' => Commands::Report
}.freeze

def parse(line)
  text = line.strip
  SIMPLE_COMMANDS[text]&.new || parse_place(text)
end
```

**How, for `"MOVE\n"`:**
1. `strip` → `"MOVE"`
2. Hash lookup → `Commands::Move`
3. `&.new` → a Move object (if the lookup was `nil`, you get `nil` and no crash)
4. `||` → only if still `nil`, try PLACE

**Code (PLACE), with a commented regex:**

```ruby
PLACE = /
  \A                    # start of the line
  PLACE[ ]              # the keyword and exactly one space
  (?<x>-?\d+)           # x: whole number, may be negative (the table rejects it later)
  ,\s*                  # comma, optional spaces
  (?<y>-?\d+)           # y: same as x
  ,\s*                  # comma, optional spaces
  (?<facing>[A-Z]+)     # heading in capitals; Direction.find checks it is a real one
  \z                    # end of the line, nothing extra allowed
/x
```

**Why:**
- `PLACE 99,99,NORTH` parses fine. **The table rejects it at run time.** One rule, one place.
- Returning `nil` (not raising) lets the simulator skip bad lines and carry on.

**Watch out:**
- The `/x` flag ignores spaces in the pattern, so a real space is written `[ ]`.
- `Integer("08", 10)`: the `10` means decimal. Without it, `"08"` is read as octal and errors.

---

## 8. Simulator

**TL;DR:** For each line: parse → skip or run → keep the result. **Holds the "discard until placed" rule.**

**File:** `lib/toy_robot/simulator.rb`

**Code:**

```ruby
def initialize(output:, table: Table.new, parser: Parser.new)
  @output, @table, @parser, @robot = output, table, parser, nil
end

def run(lines)
  lines.each { |line| execute(@parser.parse(line)) }
  self
end

def execute(command)
  return if command.nil?                              # 1. not understood → skip
  return if command.requires_robot? && robot.nil?     # 2. not placed yet → skip
  @robot = command.call(robot, table: @table, output: @output)   # 3. run
end
```

**How (full trace):**

```
line               parsed    robot before   rule      robot after
MOVE               Move      nil            2 skip    nil
PLACE 5,5,NORTH    Place     nil            3 run     nil   (off table)
JUMP               nil       nil            1 skip    nil
PLACE 1,1,EAST     Place     nil            3 run     (1,1,EAST)
MOVE               Move      (1,1,EAST)     3 run     (2,1,EAST)
REPORT             Report    (2,1,EAST)     3 run     prints 2,1,EAST
```

**Why:**
- It asks `requires_robot?` and **never checks "is this a Place?"**, so new commands need no change here.
- `lines` can be an array, a file or `$stdin`. **All inputs share one code path.**
- Table, parser and output are passed in, so tests swap them freely.

---

## 9. CLI

**TL;DR:** Reads options, picks file or stdin, reports errors, **returns an exit code.**

**Files:** `bin/toy_robot` (3 lines, no logic) and `lib/toy_robot/cli.rb`

**Code:**

```ruby
def run
  files = options.parse(@argv)
  return usage(@stdout, status: 0) if @help
  raise UsageError, 'expected at most one FILE' if files.size > 1

  files.empty? ? simulate(@stdin) : simulate_file(files.first)
rescue OptionParser::ParseError, UsageError => e
  @stderr.puts("toy_robot: #{e.message}")
  usage(@stderr, status: 1)
rescue Interrupt
  @stderr.puts      # Ctrl-C: newline, no stack trace
  INTERRUPTED       # 130
end
```

**Use it:**

```bash
bin/toy_robot examples/c_complex_sequence.txt   # from a file
bin/toy_robot < examples/b_rotation.txt         # from stdin
bin/toy_robot --size 7x3 commands.txt           # other table size
bin/toy_robot                                   # type commands; Ctrl-D to finish
```

**Exit codes:**

| Code | When |
| --- | --- |
| 0 | ran fine, `--help`, or Ctrl-D |
| 1 | bad option, bad size, too many files, unreadable file |
| 130 | Ctrl-C |

**Where output goes:**

| stdout | stderr |
| --- | --- |
| REPORT results, `--help` | errors, usage after a mistake, the Ctrl-C newline |

**Why:**
- The streams are passed in, so **the whole CLI is tested in memory.**
- `OptionParser` builds `--help` from the option definitions. **Help can't drift from reality.**
- `0x5` → `Table` raises "width must be at least 1" → the CLI shows it. The size rule stays in `Table`.

**Watch out:**
- Typing with no file shows **no prompt**. It can look stuck. It's waiting for input.
- A Ctrl-C in the first few milliseconds, while Ruby is still loading, can still show a trace.

---

## 10. Tests

**TL;DR:** Two layers. **Unit specs** per class (written first). **Acceptance specs** run the real program.

**Layout:**

```
spec/lib/          one spec per class, mirrors lib/
spec/acceptance/   runs bin/toy_robot as a real process
spec/support/      robot_at(1, 2, 'EAST') and friends
examples/          NAME.txt (commands) + NAME.expected (output)
```

**Run:**

```bash
bundle exec rspec                                   # all 140
bundle exec rspec spec/lib/toy_robot/move_spec.rb   # one file
bundle exec rspec spec/acceptance                   # end-to-end only
```

**How the acceptance layer works:**
- For every `examples/*.txt`: run the program **twice** (file argument + piped in).
- Check stdout matches `.expected`, stderr is empty, and the exit code is 0.
- **Add a case without Ruby:** drop in `k_my_case.txt` + `k_my_case.expected`.

**TDD in the history (`git log --reverse`):**
1. Write the spec → 2. watch it fail → 3. write the code → 4. watch it pass → 5. commit both.
- One class per commit, in build order.
- The exception: acceptance specs came after the code. They were proven able to fail by breaking one `.expected` on purpose.

**Settings (`spec/spec_helper.rb`):**

| Setting | Why |
| --- | --- |
| `minimum_coverage 100` | run fails if any line isn't run by a test |
| `order = :random` | catches tests that secretly depend on each other |
| `warnings = true` | Ruby warnings show during tests |

**Watch out:**
- 100% coverage means every line **runs**. It doesn't mean every line is **checked**. Mutation testing would prove that.

---

## 11. Tooling and CI

**TL;DR:** RuboCop for style, SimpleCov for coverage, RubyCritic for quality. **CI runs 4 jobs on every push.**

| Tool | Command | Status |
| --- | --- | --- |
| RSpec | `bundle exec rspec` | 140 examples, 0 failures |
| SimpleCov | (runs with rspec) | 100% line coverage |
| RuboCop | `bundle exec rubocop` | no offenses |
| RubyCritic | `bundle exec rubycritic` | every file A, except `cli.rb` = B |

**Versions:**
- Ruby **4.0.7** (`.ruby-version`). CI also tests 3.4.
- `Gemfile.lock` pins every gem. It includes the Linux platform so CI matches your Mac.
- **No runtime gems.** You only need Ruby to run it.

**CI** (`.github/workflows/test.yml`): Ubuntu + macOS × Ruby 4.0 + 3.4 = **4 jobs**, each running RuboCop then RSpec.

**Watch out: the `vendor/` line in `.rubocop.yml`**
- CI installs gems into `vendor/bundle`.
- Our `Exclude` list **replaces** RuboCop's defaults, so `vendor/` must be listed by hand.
- Without it RuboCop checks the gems' own files and crashes. **Don't delete that line.**

**Why `cli.rb` is B:** the `OptionParser` setup block makes many `parser.` calls, which Reek reads as smells. Moving option setup into its own class would fix it. It's listed under next steps.

**Accepted Reek warnings** (deliberate, also listed in the README):
- "doesn't use instance state" on commands: stateless commands are the point.
- "unused parameters" on `Command#call`: it's the base version that only raises.
- "refers to `match` a lot" in `parse_place`: reading a regex match is its job.

---

## 12. Trade-offs and next steps

**TL;DR:** Simple and safe, but **it can't tell you *why* a command was ignored.** That's the main limit.

**Assumptions:**

| Assumption | Easy to change? |
| --- | --- |
| 5 x 5 default (page 1 missing) | yes: `--size` |
| Invalid lines ignored without a message | needs outcome reporting |
| Upper-case keywords only | one regex / hash |
| Output `X,Y,F` | one method: `Robot#to_s` |

**Trade-offs made:**
1. **Silent ignoring.** Returning a robot throws away the reason. Fine for files, weak for typing.
2. **`Data.define`.** Short, but less familiar. Plain classes would be ~15 lines more each.
3. **New command object per line.** Harmless. Shared instances would be tidier.
4. **One robot, one table.** More robots or obstacles would change Simulator and Table, not the commands.

**Done since the first build:**
- [x] `--size WIDTHxHEIGHT` option
- [x] Commented multi-line PLACE regex
- [x] Ctrl-C exits with 130 and no stack trace

**Next, in order:**
1. **Simulator reports outcomes** (applied / ignored: not placed / ignored: would fall / not understood). This is the one real design change.
2. **REPL:** prompt, `HELP`, `EXIT`, feedback on stderr. Starts when stdin is a terminal, or with `-i`.
3. **Mutation testing** (`mutant`): prove the tests catch real changes.
4. **Property-based tests:** random command sequences, and the robot never leaves the table.
5. **Bring `cli.rb` back to an A:** move the `OptionParser` setup into its own class.

**Open decisions:**
- REPL: with "why ignored" feedback, or prompt/help/exit only?
- Keep `Data.define`, or switch to plain classes?
- Shared command instances: tidy up or leave?

---

## Ruby cheat sheet

Short answers for the syntax used above.

### `Data.define`

**A one-line way to make a small class whose values can't change.**

```ruby
Position = Data.define(:x, :y)       # "make a class with fields x and y, call it Position"

p = Position.new(x: 1, y: 2)
p.x                 # => 1
p.x = 5             # NoMethodError: no setter, it's read-only
p2 = p.with(x: 5)   # new Position (5,2); p is still (1,2)
p == Position.new(x: 1, y: 2)   # => true, compared by value
```

Same idea as `Dog = Class.new`: a class is a value you store in a constant. `Data.define` just comes with fields, equality and read-only built in.

### Other syntax

| Syntax | Means | Example |
| --- | --- | --- |
| `a&.b` | call `b` only if `a` isn't nil | `SIMPLE_COMMANDS[text]&.new` |
| `a \|\| b` | use `a`; if it's nil or false, use `b` | `... \|\| parse_place(text)` |
| `cond ? x : y` | short if/else | `ok ? moved : robot` |
| `**` in a method | accept and ignore extra keyword args | `def call(robot, **)` |
| `0...5` | range 0 to 4 (5 excluded) | `@x_range = 0...width` |
| `0..5` | range 0 to 5 (5 included) | not used here |
| `/…/x` | regex with spaces and `#` comments allowed | the PLACE pattern |
| `StringIO` | a string that behaves like a file | test output capture |
| `freeze` | object can't be changed after this | `Table`, `Direction::CLOCKWISE` |
| `$stdin` / `$stdout` / `$stderr` | keyboard input / normal output / error output | wired in `bin/toy_robot` |
