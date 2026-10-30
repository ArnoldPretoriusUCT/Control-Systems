# Virtual Labs

Weekly hands-on labs for MEC3079S Control Systems, written as MATLAB Live Scripts. Each lab works through one topic from the course notes: you model systems, run code and answer questions about the results.

## The labs

| Lab | Topic | Course notes |
|---|---|---|
| [Virtual Lab 1](VirtualLab1.mlx) | The mass-spring-damper system | Chapters 2–3 |
| [Virtual Lab 2](VirtualLab2.mlx) | The armature-controlled DC motor | Chapters 3–4 |
| [Virtual Lab 3](VirtualLab3.mlx) | Torsional mass-spring-damper system | Chapters 4–5 |
| [Virtual Lab 4](VirtualLab4.mlx) | System characterisation | Chapters 5–6 |
| [Virtual Lab 5](VirtualLab5.mlx) | Underdamped second-order systems | Chapters 6–7 |
| [Virtual Lab 6](VirtualLab6.mlx) | Closed-loop stability | Chapter 9 |
| [Virtual Lab 7](VirtualLab7.mlx) | Steady-state error | Chapter 10 |
| [Virtual Lab 8](VirtualLab8.mlx) | Design specifications | Chapter 11 |

The matching chapters are in [`../Notes`](../Notes), and the chapter apps in [`../Apps`](../Apps) are useful for exploring the same ideas interactively.

## How to use

1. Download the repository (**Code → Download ZIP** on GitHub, or `git clone`), or use the *Open in MATLAB Online* button on the main repository page.
2. Open a lab's `.mlx` file in MATLAB.
3. In the **View** tab, choose **Output on Right**. The labs are laid out for this view.
4. Work through the lab **section by section**: click in a section and press **Run Section** (Ctrl/Cmd + Enter). Later sections use variables from earlier ones, so run them in order.
5. Answer the questions as you go. At UCT the answers are submitted in the course's LMS (Amathuba), not in the Live Script.

Use `help` in the Command Window for information on any function, e.g. `help laplace`.

## Requirements

- MATLAB (created with R2023a; works with later releases)
- Control System Toolbox
- Symbolic Math Toolbox

UCT students and staff can use these through the Campus Wide License, either in desktop MATLAB or in [MATLAB Online](https://matlab.mathworks.com).
