# Interactive Chapter Apps

One interactive MATLAB app per chapter of the MEC3079S Control Systems course notes. Each app follows the sections and worked examples of its chapter, so you can explore the ideas by changing values and dragging things on the plots instead of only reading about them.

## Getting started

### Requirements
- MATLAB (developed and tested with R2025b; a recent release is recommended)
- Control System Toolbox (all apps)
- Symbolic Math Toolbox (Chapters 2, 3, 4 and 5; optional for Chapter 13)

UCT students and staff can use all of these through the Campus Wide License, either in desktop MATLAB or in [MATLAB Online](https://matlab.mathworks.com).

### Download
- **Whole repository:** on the GitHub page click **Code → Download ZIP** and unzip it, or clone it:
  ```
  git clone https://github.com/ArnoldPretoriusUCT/Control-Systems.git
  ```
- **A single app:** open the `.m` file on GitHub and click the download button (**Download raw file**). Each app is one self-contained file.
- **MATLAB Online:** use the *Open in MATLAB Online* button on the main repository page.

### Run
1. In MATLAB, change the current folder to `Apps` (or add it to the path with `addpath`).
2. Type the app's name in the Command Window and press Enter, for example:
   ```matlab
   Chapter6_SystemCharacterisationApp
   ```
   You can also open the file and press **Run**.

Type `help` followed by the app's name (e.g. `help Chapter9_StabilityOfClosedLoopSystemsApp`) to see a summary of its tabs and interactions.

## How the apps work

Every app has the same layout:
- **Tabs** across the top, one per main section of the chapter.
- **A control column** on the left with an **Example** list (the worked examples from the notes, plus *Custom*), the values you can edit, and a **Results** box.
- **Plots** on the right, which you can interact with directly:
  - drag poles (×) and zeros (○) in the s-plane;
  - drag curves up and down to change a gain;
  - drag markers, lines and cursors (frequencies, specifications, time constants, and so on).

  The rest of the tab updates as you drag.

Transfer functions are typed as MATLAB expressions in `s`, for example `10/(s*(s+2))`, `(s+5)/(s^2+10*s+25)` or `5*exp(-0.01*s)/(1+s/12)`. Signals in time are typed as expressions in `t`, for example `sin(10*t)`.

## The apps

| Chapter | App | What it contains |
|---|---|---|
| 1 | `Chapter1_IntroductionApp` | Five live, game-like simulations that show what control does, before any theory: an **elevator** (speed, comfort, stopping level), a **toaster** (timer vs colour sensor), a **toilet cistern** (timed valve vs float valve), **balancing an inverted pendulum** yourself and then with a controller, and **cruise control** over hills. Click a floor to call the elevator; drag the speed plot to change the cruise speed. |
| 2 | `Chapter2_SignalsAndSystemsApp` | **System properties** (linearity, time invariance and causality tested numerically), **ODE to P(s)** with draggable poles and zeros, **Laplace transforms** and their properties, and **P(s) from input–output data**. |
| 3 | `Chapter3_BlockDiagramsApp` | **Cascade, parallel and feedback** forms, **equivalent forms** (drag a block over a summing junction or pickoff point), step-by-step **block diagram reduction** of the notes' examples, and **signal paths** in the general loop, with the forward path and loop highlighted. |
| 4 | `Chapter4_ModellingInTheLaplaceDomainApp` | **Laplace transform table**, a **series RLC circuit**, translational and rotational **mass–spring–dampers** (animated), **gears** with reflected impedances, and a **gear train**. Drag the poles to set component values. |
| 5 | `Chapter5_PredictionOfSystemResponseApp` | **Poles and zeros**, the **response** from partial fractions (each pole's term in its own colour), **stability** regions, and the **initial and final value theorems** and when they apply. |
| 6 | `Chapter6_SystemCharacterisationApp` | **First-order** systems, **second-order types** (overdamped to undamped), **underdamped specifications** (T_p, %OS, T_s and pole locations), **extra poles and zeros**, and **identifying a model from step-response data**. |
| 7 | `Chapter7_FrequencyResponseTechniquesApp` | **Sinusoidal steady-state response**; **Nyquist, Bode and log-polar plots** of the same system with a shared frequency cursor; reading **characteristics** (DC gain, integrators, relative degree) off the frequency response; and **filters** (low-pass, high-pass, band-pass). |
| 8 | `Chapter8_FeedbackControlSystemsApp` | **Open loop vs closed loop** with an uncertain plant, the **gang of four** (S, T, PS, GS) picked from a clickable block diagram, and the **cost of feedback** (reference, disturbance and noise acting together). |
| 9 | `Chapter9_StabilityOfClosedLoopSystemsApp` | **Closed-loop poles** from L(s), the **stability test** on Nyquist, Bode and log-polar plots, **gain, phase and stability margins**, and **conditional stability**. |
| 10 | `Chapter10_SteadyStateErrorApp` | **Reference tracking** (system type, K_p, K_v, K_a), **P-control design** for an error specification, **disturbances**, and reading the error constants off the **frequency response**. |
| 11 | `Chapter11_TransientDesignSpecificationsApp` | **M contours** (Nyquist, Nichols, inverse Nichols, Bode), **first-order design**, **reference models**, and **tracking and disturbance bounds** shown as stay-out regions for L(jω). |
| 12 | `Chapter12_FrequencyDomainDesignApp` | **Loop shaping** of P, PI, PD (lead) and PID controllers in the log-polar plane against the tracking bounds: drag the L(jω) locus, see the controller's Bode diagram (zero, α, ω_max, β) and check the step response. Includes the notes' worked designs and a methodology tab. |
| 13 | `Chapter13_DigitalControlSystemsApp` | **Sampling and hold** (aliasing, ZOH, quantisation), **sampling in the loop**, the **Z-transform**, the **Tustin transform** (s-plane to z-plane mapping and frequency warping), and a **digital controller** with its difference equation and generated MATLAB/Arduino code. |

## Notes
- The apps go with the course notes in [`../Notes`](../Notes); section numbers in the apps refer to those notes.
- Chapter 1 runs real-time simulations; switching tabs pauses them, and closing the window stops them.
- If an entered expression is invalid, the Results box shows the error. Fix the entry and press **Update**.
