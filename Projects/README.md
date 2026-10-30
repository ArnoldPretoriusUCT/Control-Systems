# Projects

Design projects for MEC3079S Control Systems. In each one you model a system, turn the requirements into closed-loop specifications, design a feedback controller with the frequency-domain methods from the course notes (Chapters 11 and 12), and then test it on a simulation.

Every student gets their own plant parameters, generated from their **PeopleSoft number**. Enter it where the project asks, and remember that a controller copied from someone else will not suit your system.

## The projects

### [Project 1](Project%201) — Altitude control of a quadrotor
Design an altitude (height) controller for a quadrotor that can only move up and down.
- **Part 1:** model the quadrotor and identify its parameters from a Simulink simulation.
- **Part 2:** design an inner velocity controller (P, then PI) and an outer altitude controller, then test them on the "real" Simulink model with a UAV animation.
- **Files:**
  - `Project.mlx`: the project Live Script.
  - `Project.slx`: the Simulink model. Keep both files in the same folder.
- **Requires:** Simulink and the UAV Toolbox, in addition to the toolboxes below.

### [Project 2](Project%202) — Altitude control of a Flappy Bird robot
Steer a Flappy Bird robot through ever narrower gaps between pillars, first by hand, then with your own feedback controller.
- **Part 1** (`Part 1/Project_Part1.mlx`): model the robot and derive the closed-loop performance specifications.
- **Part 2** (`Part 2/Project_Part2.mlx`): design the controller and let it fly the game.
- **Installing the game:** each part comes with the game as a MATLAB toolbox (`FlappyBirdPart1.mltbx`, `FlappyBirdPart2.mltbx`). Set MATLAB's current folder to that part's folder and install it with, for example:
  ```matlab
  matlab.addons.install('FlappyBirdPart1.mltbx');
  ```

### [Project 3](Project%203) — Gotta Catch 'Em All! (ball-catching cart)
Design a position controller for a cart on a track that has to catch Poke Balls dropped from random positions.
- **Parts:**
  1. System identification
  2. Closed-loop specifications
  3. Control design
  4. Implementation on the simulator, scored by the number of catches
- **Files:**
  - `student_workspace.mlx`: the project Live Script.
  - `run_cart_simulation.p`: the cart simulator, called from the Live Script. It is a protected file, so it cannot be opened, only run. Keep it in the same folder.

## How to use

1. Download the repository (**Code → Download ZIP** on GitHub, or `git clone`), or use the *Open in MATLAB Online* button on the main repository page.
2. Set MATLAB's current folder to the project's folder, so the Live Script can find its Simulink model, game toolbox or simulator.
3. Open the project's Live Script and work through it section by section with **Run Section** (Ctrl/Cmd + Enter), entering your PeopleSoft number first.
4. Submit your completed files as the project instructs, with your student number added to the file names.

## Requirements

- MATLAB (created with R2023a; works with later releases)
- Control System Toolbox
- Symbolic Math Toolbox
- Simulink and UAV Toolbox (Project 1 only)

UCT students and staff can use these through the Campus Wide License, either in desktop MATLAB or in [MATLAB Online](https://matlab.mathworks.com).

Worked solutions are not included. Educators can request them from the author (see the main [README](../README.md)).
