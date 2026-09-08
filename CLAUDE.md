# UTMB 2026 Analysis

Analysis of the **UTMB® Mont-Blanc 2026** trail race, in R. Advertised as 171 km / 10 000 m D+; the timing points give **173.6 km / 9 700 m** (see `R/checkpoints.R`), which is the figure the reports use.

## Goals

Explore questions such as:

- **Rest time** — how long runners spend stopped at aid stations, and how it relates to finish time / fatigue.
- **UTMB Index vs actual performance** — does the pre-race index predict the finish rank?
- More to come (pacing / positive-vs-negative split, category effects, DNF patterns, ...).

## Data source

Data is scraped from the public UTMB Live API (the backend of https://live.utmb.world).

- **Base URL:** `https://utmblive-api.utmb.world`
- **Required header:** `X-Tenant: utmb_2026` (this selects the 2026 edition)
- **Race slug:** `utmb` (other 2026 races on the same edition: `ccc`, `occ`, `tds`, `pdg`, `mcc`, `etc`)

Key endpoints (all need the `X-Tenant` header):

| Endpoint | Purpose |
|---|---|
| `GET /races/{race}` | Race summary: start date, `statistic` (starters / finishers / DNF), checkpoint crossing distribution |
| `GET /races/{race}/progressive?type=FINAL_RANKING&limit={n}&page={p}` | Paginated final ranking (finishers only). `page` is 0-indexed. Response has `runners[]` and `totalRunner`. |
| `GET /runners/{bib}` | One runner: `resume` (identity, ranking, finish time) + `detail.passings[]` (per-checkpoint splits) + `detail.totalRestTimeSeconds` |
| `GET /runners/search/quick-search?search={q}&limit={n}` | Name search |

Notes:
- `FINAL_RANKING` is the only working `type`, and it returns **finishers only** (1 681). To get **DNFs** we enumerate bib numbers against `/runners/{bib}` (see `R/scrape_all_runners.R`): every starter — finisher or not — carries a UTMB Index, a `status`, and partial splits.
- `status` codes: `f` = finisher, `a` = abandon (DNF), `hd` = hors délai / cut-off (DNF), `np` = did-not-start, `s` = other. Coarse `outcome` = Finisher / DNF / Other.
- Full field ≈ 2 402 starters (1 681 finishers + 721 DNF), plus ~61 DNS bibs. Highest bib ≈ 2 700.
- `info.index` in the ranking is the runner's **UTMB Index**, and it is **edition-contemporaneous** — scraping the 2024 edition returns each runner's 2024-era index, not today's. (Verified: only ~1% of runners appearing in both 2024 and 2026 carry an identical index.)
- Checkpoint identity is a numeric `pointId` (0 = start, 200 = finish in 2026). There is no public endpoint mapping `pointId` → name/km.
- **The `pointId` scheme is NOT shared across editions**: 2026 numbers its timing points 4/6/10/…/82/200, while 2024 and 2025 use 2/3/4/…/44/144. `R/checkpoints.R` is therefore 2026-only.
  - For cross-edition work use `derive_checkpoints(passings)` in `R/checkpoints.R`, which rebuilds any edition's distance table **from the passings themselves** (`section km = speed × split_time`, median across runners, with low-coverage aid-station *exit* rows forced to zero length). It reproduces the hand-read 2026 table to within **0.1 km**.
  - Reconstructed course lengths: 176.7 km (2024), 175.4 km (2025), 173.6 km (2026). The first timing point (the Col de Voza climb) sits at 13.2 / 14.6 / 14.4 km respectively.

## Project structure

```
R/
  scrape_utmb.R          # fast path: ranking (finishers) + detail -> CSVs
  scrape_all_runners.R   # full field: enumerate bibs -> finishers + DNFs
  checkpoints.R          # pointId -> name / cum km / cum D+ + per-section km/D+
analysis/
  utmb_2026_analysis.qmd     # single Quarto report: index, rest time, per-stage
data/
  raw/               # raw JSON responses (git-ignored, reproducible)
  processed/         # tidy CSVs (see below)
```

Processed datasets:
- `runners_utmb.csv` / `passings_utmb.csv` — finishers only (from `scrape_utmb.R`).
- `runners_all_utmb.csv` / `passings_all_utmb.csv` — **full field incl. DNFs**, 2026 (from `scrape_all_runners.R`); use these for seed-vs-finish work.
- `runners_all_utmb_2024.csv` / `passings_all_utmb_2024.csv`, and the same pair for `2025` — full fields for the prior editions (from `scrape_history.R`).
- `index_performance_utmb.csv` — per-runner seed / result / over-performance table (written by the Quarto report).
- `pacing_blowup_utmb.csv` — per-runner overpace / band / DNF table (written by `blowup_pacing.qmd`).
- `tangi_cross_year.csv` — per-edition seeds, per-lens projections, method spread and bootstrap range (written by `tangi_cross_year.qmd`).

## Running the scraper

```bash
# Full scrape (all 1681 finishers + their splits; ~a few minutes)
Rscript R/scrape_utmb.R

# Quick test: only the first N finishers' detail
Rscript R/scrape_utmb.R 25
```

Outputs:
- `data/processed/runners_utmb.csv` — one row per finisher (identity, UTMB index, ranks, finish time in seconds, total rest time in seconds).
- `data/processed/passings_utmb.csv` — one row per runner × checkpoint (cumulative time, split pace/speed, rank, rest time).

Full field including DNFs:

```bash
Rscript R/scrape_all_runners.R        # all bibs 1..2750 (~6 min)
Rscript R/scrape_all_runners.R 1 60   # quick test on bibs 1..60
```

Past editions (writes both `runners_all_utmb_<year>.csv` **and** `passings_all_utmb_<year>.csv`):

```bash
Rscript R/scrape_history.R 2025       # full field, bibs 1..3200 (~7 min)
Rscript R/scrape_history.R 2024 1 60  # quick test
```

## Analysis reports (Quarto)

Reports live in `analysis/*.qmd`. Native render (preferred):

```bash
quarto render analysis/index_vs_performance.qmd
```

Quarto CLI must be installed (`brew install --cask quarto`, needs your admin password). Without it, render an HTML preview using the already-installed `rmarkdown` + `pandoc` (the `.qmd`s set `echo: false`, so no code is shown):

```bash
Rscript -e 'rmarkdown::render("analysis/utmb_2026_analysis.qmd", \
  output_format = rmarkdown::html_document(self_contained = TRUE, toc = TRUE, \
  theme = "cosmo", df_print = "kable"), output_file = "utmb_2026_analysis.html")'
```

## Conventions

- R style: modern **tidyverse** (native pipe `|>`, `dplyr` 1.1+, `httr2`, `purrr` + `list_rbind`).
- Be polite to the API: the scraper throttles requests and retries on transient errors.
- Times from the API are `HH:MM:SS` / `H:MM:SS` strings; seconds fields (`timeSeconds`, `totalRestTimeSeconds`) are numeric and preferred for analysis.
