# MECH9325-MATLAB-AIO

**Acoustics & Noise Toolkit** — a search-driven, all-in-one acoustics and noise
calculator for MATLAB. A single programmatic App Designer–style GUI mirrors the
MECH9325 web app: type in the search box to filter the list of calculators on
the left, and the selected calculator's form appears on the right.

Every calculator shows not just the answer but the **full working** (formulae and
substituted numbers), making it useful for checking hand calculations and study.

## Requirements

- MATLAB **R2018b or newer** (needs `uifigure`, `uigridlayout` and related App
  Building functions).
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

The toolkit ports the full MECH9325 quiz material — around 50 calculators,
grouped below. Each one prints the substituted formula and working alongside the
answer.

**Levels & conversions**
- SPL ↔ RMS pressure (`Lp = 20·log10(p / 2e-5)`)
- Sound power level `Lw` ↔ power `W`
- Sound intensity level `LI` (and `I = p²/ρc`)
- Peak ↔ RMS (`p_rms = P/√2`) and combining component RMS pressures
- PSD → RMS pressure (integrate a band: `p_rms² = ½(S₁+S₂)(f₂−f₁)`)

**Combine / subtract**
- Combine (energy-sum) a list of levels
- `N` identical sources (`L_tot = L1 + 10·log10(N)`)
- Increase when more sources are added
- Error from using only the larger of two signals
- Maximum number of sources under a level limit
- Remove a background / one source (energy subtraction)
- One of `N` identical sources

**Waves**
- `c = f·λ` (with period, ω, wavenumber)
- Speed of sound from temperature
- Particle velocity & displacement
- Octave / ⅓-octave band edges and closed-pipe natural frequencies

**Distance & sound power**
- Distance attenuation: point (−6 dB/doubling) and line (−3 dB/doubling) sources
- Solve source distance from two measured levels
- `Lw` ↔ `Lp` at a distance (free field, ground, edge, corner; line sources)
- Background (K₁) and environmental (K₂) corrections
- Sound power level from surface SPL measurements
- `Lw` from free-field band SPLs (un-weight + measurement-surface area)
- Duct sound power → microphone voltage (with plane-wave cut-on check)

**Room acoustics**
- Sabine reverberation time (solve any one of `V`, `S`, `ᾱ`, `T₆₀`)
- Average absorption coefficient
- Room constant `R`
- Room equation `Lp` from `Lw` (direct + reverberant field)
- Reverberant level change when absorber panels are added/removed

**Spectra**
- A / B / C (or Z) weighting & overall level for octave or ⅓-octave bands
- Band Workbench: ⅓-octave → octave → overall & weighted level

**Time, exposure & community**
- `Leq` from levels & durations (units supported), plus `SEL`
- `Leq` from discrete events (pass-bys)
- `Leq` & percentile `LN` for a time-varying level (with plot)
- Occupational noise dose, `L_Aeq` and maximum permissible time
- Maximum permissible time for a steady level
- Community day–night level `Ldn`

**Perception & statistics**
- Loudness: phons ↔ sones
- Speech interference level (PSIL) & voice effort
- `SEL` ↔ `Leq`; sorting fluctuating-noise values into terms

**Insulation & mufflers**
- Mass-law transmission loss
- Interface impedance ratio & transmission/reflection coefficients
- TL from a transmission coefficient
- Panel resonance frequency
- Muffler sudden area change & expansion-chamber TL
- TL / IL / NR level difference

**Reference**
- A / B / C weighting network table (IEC 61672 family)

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
