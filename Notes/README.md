# Course Notes

The MEC3079S Control Systems course notes: thirteen chapters written as MATLAB Live Scripts, which together form an interactive textbook with numbered sections, figures, LaTeX equations and runnable code.

## Formats

Each chapter is available in three forms:

| Format | Folder | Use it to |
|---|---|---|
| **Live Script** (`.mlx`) | this folder | Read the notes **and** run, edit and experiment with the code and the interactive controls (sliders, dropdowns, checkboxes). |
| **PDF** | [`PDF Exports`](PDF%20Exports) | Read or print a static copy; no MATLAB needed. |
| **HTML** | [`HTML Exports`](HTML%20Exports) | Read a static copy in a web browser; no MATLAB needed. Download the file and open it locally, because GitHub shows HTML files as source code. |

The PDF and HTML files are exported automatically from the Live Scripts.

## Chapters

| Ch. | Title | Notes | | | Interactive app |
|---|---|---|---|---|---|
| 1 | Introduction | [Live Script](MEC3079S_Chapter1_Introduction.mlx) | [PDF](PDF%20Exports/MEC3079S_Chapter1_Introduction.pdf) | [HTML](HTML%20Exports/MEC3079S_Chapter1_Introduction.html) | [App](../Apps/Chapter1_IntroductionApp.m) |
| 2 | Signals and systems | [Live Script](MEC3079S_Chapter2_SignalsAndSystems.mlx) | [PDF](PDF%20Exports/MEC3079S_Chapter2_SignalsAndSystems.pdf) | [HTML](HTML%20Exports/MEC3079S_Chapter2_SignalsAndSystems.html) | [App](../Apps/Chapter2_SignalsAndSystemsApp.m) |
| 3 | Block diagrams | [Live Script](MEC3079S_Chapter3_BlockDiagrams.mlx) | [PDF](PDF%20Exports/MEC3079S_Chapter3_BlockDiagrams.pdf) | [HTML](HTML%20Exports/MEC3079S_Chapter3_BlockDiagrams.html) | [App](../Apps/Chapter3_BlockDiagramsApp.m) |
| 4 | Modelling in the Laplace domain | [Live Script](MEC3079S_Chapter4_ModellingInTheLaplaceDomain.mlx) | [PDF](PDF%20Exports/MEC3079S_Chapter4_ModellingInTheLaplaceDomain.pdf) | [HTML](HTML%20Exports/MEC3079S_Chapter4_ModellingInTheLaplaceDomain.html) | [App](../Apps/Chapter4_ModellingInTheLaplaceDomainApp.m) |
| 5 | Prediction of system response | [Live Script](MEC3079S_Chapter5_PredictionOfSystemResponse.mlx) | [PDF](PDF%20Exports/MEC3079S_Chapter5_PredictionOfSystemResponse.pdf) | [HTML](HTML%20Exports/MEC3079S_Chapter5_PredictionOfSystemResponse.html) | [App](../Apps/Chapter5_PredictionOfSystemResponseApp.m) |
| 6 | System characterisation | [Live Script](MEC3079S_Chapter6_SystemCharacterisation.mlx) | [PDF](PDF%20Exports/MEC3079S_Chapter6_SystemCharacterisation.pdf) | [HTML](HTML%20Exports/MEC3079S_Chapter6_SystemCharacterisation.html) | [App](../Apps/Chapter6_SystemCharacterisationApp.m) |
| 7 | Frequency response techniques | [Live Script](MEC3079S_Chapter7_FrequencyResponseTechniques.mlx) | [PDF](PDF%20Exports/MEC3079S_Chapter7_FrequencyResponseTechniques.pdf) | [HTML](HTML%20Exports/MEC3079S_Chapter7_FrequencyResponseTechniques.html) | [App](../Apps/Chapter7_FrequencyResponseTechniquesApp.m) |
| 8 | Feedback control systems | [Live Script](MEC3079S_Chapter8_FeedbackControlSystems.mlx) | [PDF](PDF%20Exports/MEC3079S_Chapter8_FeedbackControlSystems.pdf) | [HTML](HTML%20Exports/MEC3079S_Chapter8_FeedbackControlSystems.html) | [App](../Apps/Chapter8_FeedbackControlSystemsApp.m) |
| 9 | Stability of closed-loop systems | [Live Script](MEC3079S_Chapter9_StabilityOfClosedLoopSystems.mlx) | [PDF](PDF%20Exports/MEC3079S_Chapter9_StabilityOfClosedLoopSystems.pdf) | [HTML](HTML%20Exports/MEC3079S_Chapter9_StabilityOfClosedLoopSystems.html) | [App](../Apps/Chapter9_StabilityOfClosedLoopSystemsApp.m) |
| 10 | Steady-state error | [Live Script](MEC3079S_Chapter10_SteadyStateError.mlx) | [PDF](PDF%20Exports/MEC3079S_Chapter10_SteadyStateError.pdf) | [HTML](HTML%20Exports/MEC3079S_Chapter10_SteadyStateError.html) | [App](../Apps/Chapter10_SteadyStateErrorApp.m) |
| 11 | Transient design specifications | [Live Script](MEC3079S_Chapter11_TransientDesignSpecifications.mlx) | [PDF](PDF%20Exports/MEC3079S_Chapter11_TransientDesignSpecifications.pdf) | [HTML](HTML%20Exports/MEC3079S_Chapter11_TransientDesignSpecifications.html) | [App](../Apps/Chapter11_TransientDesignSpecificationsApp.m) |
| 12 | Frequency-domain design | [Live Script](MEC3079S_Chapter12_FrequencyDomainDesign.mlx) | [PDF](PDF%20Exports/MEC3079S_Chapter12_FrequencyDomainDesign.pdf) | [HTML](HTML%20Exports/MEC3079S_Chapter12_FrequencyDomainDesign.html) | [App](../Apps/Chapter12_FrequencyDomainDesignApp.m) |
| 13 | Digital control systems | [Live Script](MEC3079S_Chapter13_DigitalControlSystems.mlx) | [PDF](PDF%20Exports/MEC3079S_Chapter13_DigitalControlSystems.pdf) | [HTML](HTML%20Exports/MEC3079S_Chapter13_DigitalControlSystems.html) | [App](../Apps/Chapter13_DigitalControlSystemsApp.m) |

Each chapter has an interactive app in [`../Apps`](../Apps) that lets you explore its examples by dragging poles, curves and markers. See the [Apps README](../Apps/README.md).

## How to use the Live Scripts

1. Download the repository (**Code → Download ZIP** on GitHub, or `git clone`), or use the *Open in MATLAB Online* button on the main repository page.
2. Open a chapter `.mlx` file in MATLAB (double-click it, or use `open` in the Command Window).
3. Work through it **section by section**: click in a section and press **Run Section** (Ctrl/Cmd + Enter). The code blocks build on each other, so run them in order.
4. Change the values in the code and the interactive controls to see how the results change. The original file can always be downloaded again.

**Tip:** in the **View** tab, choose *Output Inline* to see the results under each code block, or *Hide Code* to read the notes like a textbook.

## Requirements

- MATLAB (the notes were created with R2023a and work with later releases)
- Control System Toolbox
- Symbolic Math Toolbox

UCT students and staff can use these through the Campus Wide License, either in desktop MATLAB or in [MATLAB Online](https://matlab.mathworks.com).
