# UTMB 2026 Analysis

Analysis of the **UTMB® Mont-Blanc 2026** trail race, in R. Advertised as
171 km / 10 000 m D+; the timing points give **173.6 km / 9 700 m** (see
[`R/checkpoints.R`](R/checkpoints.R)), which is the figure the reports use.

**Read the reports:** https://alexisko.github.io/UTMB/

## What's here

- Rest time at aid stations, and how it relates to finish time / fatigue.
- UTMB Index vs. actual finishing performance.
- Pacing: fast starts, blow-ups, and DNF risk by ability band.
- A cross-year projection exercise for one runner across the 2024–2026 editions.

## Data source

Data is scraped from the public UTMB Live API (the backend of
https://live.utmb.world). See [`CLAUDE.md`](CLAUDE.md) for endpoint details,
field notes, and the full project/data layout.

## Project structure

```
R/
  scrape_utmb.R          # fast path: ranking (finishers) + detail -> CSVs
  scrape_all_runners.R   # full field: enumerate bibs -> finishers + DNFs
  scrape_history.R       # prior editions (2024, 2025)
  checkpoints.R          # pointId -> name / cum km / cum D+ + per-section km/D+
analysis/
  utmb_2026_analysis.qmd # index vs. performance, rest time, per-stage
  blowup_pacing.qmd      # fast-start / blow-up / DNF analysis
  tangi_cross_year.qmd   # cross-edition projection case study
data/
  raw/               # raw JSON responses (git-ignored, reproducible)
  processed/         # tidy CSVs
docs/                # rendered HTML reports, published via GitHub Pages
```

## Running the scraper

```bash
Rscript R/scrape_utmb.R        # all finishers + splits (~a few minutes)
Rscript R/scrape_all_runners.R # full field incl. DNFs, bibs 1..2750 (~6 min)
Rscript R/scrape_history.R 2025 # prior edition, full field (~7 min)
```

## Rendering reports

```bash
quarto render analysis/utmb_2026_analysis.qmd
```

Quarto CLI must be installed (`brew install --cask quarto`). See
[`CLAUDE.md`](CLAUDE.md) for the `rmarkdown`-only fallback.
