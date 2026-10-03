# Toy Robot Simulator - Zuno Tech Assessment

> Verbatim transcription of `toy-robot-simulator-tech-test.pdf`.
> The PDF has 2 pages, footed "Page 2 of 3" and "Page 3 of 3". **Page 1 of 3 is not in the file.**

---

## Core Objectives

Create an application that can read in commands from standard input or a file (developer's choice) to control the toy robot. The application must support the following command set:

| Command | Action & Behavior |
| --- | --- |
| `PLACE X,Y,F` | Will put the toy robot on the table in position X,Y and facing `NORTH`, `SOUTH`, `EAST`, or `WEST`.<br><br>The origin `(0,0)` can be considered to be the SOUTH-WEST most corner. The first valid command to the robot is a PLACE command. After that, any sequence of commands may be issued, in any order, including another PLACE command. |
| `MOVE` | Will move the toy robot one unit forward in the direction it is currently facing. |
| `LEFT` | Will rotate the robot 90 degrees left (counter-clockwise) without changing the position of the robot. |
| `RIGHT` | Will rotate the robot 90 degrees right (clockwise) without changing the position of the robot. |
| `REPORT` | Will announce the X,Y and F of the robot. This can be in any form, but standard output is sufficient. |

## Constraints & Application Rules

- The toy robot **must not fall off the table** during movement. This also includes the initial placement of the toy robot.
- Any move that would cause the robot to fall must be ignored.
- The application should **discard all commands** in the sequence until a valid `PLACE` command has been successfully executed.
- Input can be read from a file, or from standard input, as you prefer.

Zuno Tech Group | Engineering Assessment — Page 2 of 3

---

## Required Deliverables

When submitting your completed assignment, please ensure you include the following:

- **The Application Code:** Your complete working solution.
- **Test Data & Results:** Provide test data/suites to exercise the application and prove its logic.
- **Setup Instructions:** Provide clear instructions on how to build, run, and test the application.
- **Approach Explanation:** Provide a brief written explanation of your approach to solving the problem.
- **Future Improvements:** Write a short section on what you would have done differently or how you would improve the application given more time.

## Example Scenarios

Below are examples of valid command sequences and their expected outputs.

### Scenario A: Basic Movement

Input commands:

```
PLACE 0,0,NORTH
MOVE
REPORT
```

Output:

```
0,1,NORTH
```

### Scenario B: Rotation

Input commands:

```
PLACE 0,0,NORTH
LEFT
REPORT
```

Output:

```
0,0,WEST
```

### Scenario C: Complex Sequence

Input commands:

```
PLACE 1,2,EAST
MOVE
MOVE
LEFT
MOVE
REPORT
```

Output:

```
3,3,NORTH
```

Zuno Tech Group | Engineering Assessment — Page 3 of 3
