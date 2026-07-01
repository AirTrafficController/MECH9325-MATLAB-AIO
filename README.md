# MECH9325 — MATLAB Acoustics & Noise-Control Calculator (AIO)

An all-in-one acoustics and noise-control calculator for the course **MECH9325**,
native to MATLAB. It is a port of the client-side web-app version and bundles
every calculator from the course (Units 1–8 and the quizzes) behind one
interface, with the **full working shown** for every result.

The project has two layers:

1. **`AcousticsApp`** — a programmatic App Designer–style GUI (`uifigure` /
   `uigridlayout`). A search box filters ~50 calculators; the selected one shows
   a form and prints the substituted formulae alongside the answer.
2. **`+acoustics`** — a backing library of plain functions, **one `.m` file per
   formula**, each with an `arguments` block, input validation, and a `.steps`
   field of worked-step strings. The app calls these, and you can call them
   directly from the command line or your own scripts.

> **Why a code-based GUI and not a binary `.mlapp`?** A `.mlapp` is a binary
> package that only App Designer can author. The programmatic `uifigure` app
> here is the standard, fully version-controllable equivalent — it opens with a
> single command and needs no App Designer.

## Requirements

- MATLAB **R2018b or newer** (needs `uifigure`, `uigridlayout`, and the
  `arguments` block).
- **No additional toolboxes.** The unit tests use `matlab.unittest`, which ships
  with base MATLAB.

## Getting started

```matlab
cd MECH9325-MATLAB-AIO      % folder containing AcousticsApp.m and +acoustics/
AcousticsApp                % launch the GUI
```

Type in the search box (e.g. `dBA`, `Leq`, `octave`, `dose`, `TL`, `sones`,
`speech`), pick a calculator, fill the form, and press **Compute**.

### Using the library directly

The `+acoustics` package must be on the path (running from the repo root is
enough). Every function returns a struct with the numeric outputs and a `.steps`
cell array:

```matlab
acoustics.splPressure('p', 1).Lp            % 93.98 dB   (1 Pa)
acoustics.powerLevel('W', 0.5).Lw           % 116.99 dB  (0.5 W)
acoustics.speedOfSoundTemp(20).c            % 343.2 m/s
acoustics.phonToSone(80).sones              % 16 sones
acoustics.sabineT60('V',200,'S',240,'alpha',0.15).T60

v = acoustics.voiceLevelA(103.67, 1);       % ship engine-room example
v.VLA          % 102.2 dB(A)
v.possible     % false  (exceeds 88 dB(A) peak shouting)

disp(acoustics.massLawTL(1000,'density',500,'thickness_mm',3).steps)
```

## Running the tests

```matlab
runAcousticsTests        % or:  runtests('tests')
```

The suite (`tests/acousticsValidationTest.m`) asserts the course's worked
answers, including: **1 Pa → 94 dB**, **0.5 W → 117 dB**, **c(20 °C) = 343 m/s**,
**16 sones**, **overall dB(A) = 77.5**, **LAeq,24h = 70.55**, **plywood mass-law
TL = 21 dB @ 1 kHz**, and the ship engine-room speech example
(**SIL = 103.67 dB**, **VL_A = 102.2 dB(A)**, communication **not** possible).

## Physical constants (course values)

| Quantity | Symbol | Value |
|---|---|---|
| Reference sound pressure | `p_ref` | 2 × 10⁻⁵ Pa |
| Reference sound power | `W_ref` | 1 × 10⁻¹² W |
| Reference sound intensity | `I_ref` | 1 × 10⁻¹² W/m² |
| Characteristic impedance of air | `ρc` | 415 rayls |
| Speed of sound (20 °C) | `c` | 343 m/s |

They live in `acoustics.constants`.

## Coverage

Every calculator prints the substituted formula and working alongside the
answer. Library functions are in `+acoustics/`.

| Topic | Calculators | Key library functions |
|---|---|---|
| **Levels** | SPL ↔ p; Lw ↔ W; LI and I = p²/ρc; radiated power W = I·4πr²/Q; peak ↔ RMS; combine tones; PSD → RMS | `splPressure`, `powerLevel`, `intensityLevel`, `radiatedPower`, `peakToRms`, `psdToRms` |
| **Combine** | Energy-sum levels; N identical sources; increase from more sources; error from larger-signal-only; max sources under a limit | `combineLevels`, `nIdenticalSources`, `increaseFromSources`, `largerSignalError`, `maxSourcesUnderLimit` |
| **Subtract** | Remove background/one source; one of N identical | `subtractLevels`, `oneOfNSources` |
| **Waves** | c = fλ (+ T, ω, k); speed of sound from temperature; particle velocity/displacement; octave-band edges; pipe modes | `waveRelation`, `speedOfSoundTemp`, `particleMotion`, `octaveBandEdges`, `pipeModes` |
| **Distance** | Point −6 dB & line −3 dB spreading; solve distance from two levels; Lw ↔ Lp (free field/ground/edge/corner, line) | `distanceAttenuation`, `solveDistance`, `lwLpDistance` |
| **Room acoustics** | Sabine T60 (solve any term); average absorption ᾱ; room constant R; room equation; absorber ΔLp | `sabineT60`, `averageAbsorption`, `roomConstant`, `roomEquation`, `absorberChange` |
| **Sound power** | Background K1; environmental K2; Lw from surface SPL; free-field Lw from bands | `backgroundK1`, `environmentalK2`, `soundPowerMeasured`, `lwFromBands` |
| **Duct → voltage** | Duct sound power → mic voltage (plane-wave cut-on check) | `ductToVoltage` |
| **Weighting** | A/B/C(/Z) overall level; ⅓-oct → octave band workbench; A/B/C reference table | `weightedOverall`, `bandWorkbench`, `weightingValue`, `weightingTable` |
| **Leq / time** | Leq from levels+durations (mixed units) + SEL; discrete events; time-varying Leq + percentile LN | `leqFromLevels`, `leqFromEvents`, `percentileLevel` |
| **Noise dose** | LAeq, dose %, OH&S max time; max time for a steady level | `noiseDose`, `maxPermissibleTime` |
| **Loudness** | phons ↔ sones | `phonToSone`, `soneToPhon` |
| **Speech / PSIL** | SIL; required A-weighted voice level VL_A (Unit 5 Eq 5.6); Table 5.2 effort + communication verdict vs 88 dB(A) | `speechInterferenceLevel`, `voiceLevelA` |
| **Community** | Day–night level Ldn | `dayNightLevel` |
| **Stats / SEL** | SEL ↔ Leq; sort values into terms | `selFromLeq` |
| **Insulation (TL)** | Mass-law TL; interface impedance & coefficients; TL from α_t; panel resonance | `massLawTL`, `interfaceImpedance`, `tlFromCoefficient`, `panelResonance` |
| **Mufflers** | Sudden area change; expansion-chamber TL; TL/IL/NR level difference | `mufflerAreaChange`, `expansionChamberTL`, `levelDifference` |

### Speech / voice-effort reference (Unit 5)

`voiceLevelA(SIL, r)` applies **VL_A ≥ (4/3)(SIL + 20·log₁₀ r) − 36** and
classifies the required effort against the **Table 5.2** voice-effort levels,
declaring communication impossible above the 88 dB(A) peak-shouting limit:

| Effort | A-weighted voice level, dB(A) |
|---|---|
| Normal | 57 |
| Raised | 65 |
| Very loud | 74 |
| Shouting | 82 |
| Peak shouting (max) | 88 |

## Project layout

```
AcousticsApp.m                     Search-driven GUI; each calculator calls +acoustics
+acoustics/                        Function library — one .m file per formula
    constants.m, weightingTable.m, splPressure.m, ... (54 files)
tests/acousticsValidationTest.m    matlab.unittest suite over the worked answers
runAcousticsTests.m                Convenience runner (= runtests('tests'))
README.md                          This file
LICENSE
```

## Notes & assumptions

- Two validation datasets (the spectrum behind **77.5 dB(A)** and the schedule
  behind **LAeq,24h = 70.55**) were reconstructed to reproduce the target values
  exactly, since the source web-app data was not accessible from this repo. The
  formulae and constants otherwise mirror the ported web app verbatim.
- Mass-law TL uses the ported constant: `TL = 20·log₁₀(M·f) − 42.4`.

## License

See [LICENSE](LICENSE).
