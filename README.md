# MECH9325-MATLAB-AIO

**Acoustics & Noise Toolkit** — a search-driven, all-in-one acoustics and noise
calculator for MATLAB. A single programmatic App Designer–style GUI mirrors the
MECH9325 web app: type in the search box to filter the list of calculators on
the left, and the selected calculator's form appears on the right.

Every calculator shows not just the answer but the **full working** (formulae and
substituted numbers), making it useful for checking hand calculations and study.

## Requirements

- MATLAB **R2016b or newer** (needs `uifigure` and related App Building
  functions).
- **No additional toolboxes required** — runs on base MATLAB.

## Getting Started

1. Clone or download this repository.
2. Open MATLAB and `cd` into the project folder (where `AcousticsApp.m` lives).
3. Run the app from the Command Window:

   ```matlab
   AcousticsApp
   ```

4. Use the search box at the top to filter calculators (e.g. `dBA`, `Leq`,
   `octave`, `dose`, `distance`), select one from the list, fill in the form,
   and press **Compute**.

## Calculators

| Calculator | What it does |
| --- | --- |
| **Levels: SPL / pressure / power** | Converts a sound pressure level `Lp` to RMS pressure and intensity (`p = 2e-5·10^(Lp/20)`, `I = p²/ρc`). |
| **Combine sound levels** | Energy-sums any number of decibel levels into a single combined level. |
| **N identical sources** | Total level of `N` identical sources: `L_tot = L1 + 10·log10(N)`. |
| **A / B / C Weighting** | Applies A/B/C (or Z) frequency weighting to octave or 1/3-octave band levels and reports the overall weighted level. |
| **Band Workbench** | Combines 1/3-octave band levels into octave bands, then into an overall and A/B/C-weighted level. |
| **Leq from levels & durations** | Equivalent continuous level `Leq` (and `SEL`) from level/duration pairs. |
| **Noise Dose & max time** | Worker noise dose, `L_Aeq`, and maximum permissible exposure time using a configurable criterion level, exchange rate, and criterion time. |
| **Distance attenuation** | Level at a new distance for point (spherical, −6 dB/doubling) and line (cylindrical, −3 dB/doubling) sources. |

## Frequency Weighting Data

The A/B/C weighting values are based on the IEC 61672 family and cover 1/3-octave
centre frequencies from 25 Hz to 20 kHz (see `acousticsData` at the bottom of
`AcousticsApp.m`).

## Project Layout

```
AcousticsApp.m   Single-file MATLAB class implementing the GUI and all calculators
LICENSE          License
README.md        This file
```

## License

See [LICENSE](LICENSE) for details.
