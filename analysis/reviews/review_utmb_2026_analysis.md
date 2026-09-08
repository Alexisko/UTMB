
## A. Blocking — factual errors and changed conclusions

### A1. "He rested more than any of them" is false, and contradicts its own inline number

`w_rank` = Tangi's rest rank inside the ±15 window = **2 of 31** (window max is 109 min, Tangi 87).
The sentence asserts "he rested more than any of them" and then prints "the **2nd** longest" a few words later.

It is also window-shopped — his rank moves with the window:

| window | n | median rest | Tangi's rank |
|---|---|---|---|
| ±5 | 11 | 32 min | **1** |
| ±10 | 21 | 41 min | 2 |
| ±15 | 31 | 48 min | 2 |
| ±25 | 51 | 43 min | 3 |
| ±50 | 101 | 48 min | 7 |
| ±100 | 201 | 47 min | 12 |

**Fix:** correct the prose, and show the sensitivity (with the table).

### A2. The rest coefficient is overstated by ~2.6×

`coef(lm(finish_h ~ utmb_index + rest_min))*60 = 1.62`. The text reads: *"each extra minute of rest goes with **1.6 extra minutes** of finish time — beyond the one minute it adds by definition."*
The 1.62 **already includes** the definitional minute. The excess is **0.62 min**, not 1.6 — confirmed independently, because regressing *moving* time on rest gives exactly 0.62.

**Fix:** correct the sentence, and promote the moving-time regression to the headline number since it isn't tautological. It also strengthens under the A-grade sensitivity: restricting to finishers under 42 h (away from cut-off censoring, n = 1,204) raises it from 0.62 to **0.75 min per minute**.

### A3. "+76 places on his seeding" is survivorship, and reads as praise for an average run

`seed` is a rank over **2,382 starters**; `result_pos` puts all 711 DNFs below every finisher. So every finisher gains places mechanically: mean `seed_delta` for finishers = **+272**, median **+249**. Tangi's +76 is at the **28th percentile of finishers**.

Decomposed: of his +76, **+96 places come purely from higher-rated runners DNF-ing**, leaving **−20** — on a like-for-like basis (seed and rank both computed among finishers) he finished **20 places behind his rating**. Among finishers seeded 150–350, his ρ = finish/seed = 0.67 against a group median of 0.65: **48th percentile, i.e. dead average**.

This matters doubly because `tangi_cross_year.qmd` builds its entire case on this +76 (see that note, item A1).

**Fix:** keep +76 but state alongside that 96 runners with higher seeds DNFs and that he finished 20 places behind his rating.

### A4. "The index predicts less well at the front" is range restriction — the data says the opposite

| subset | n | R² | SD(index) | residual SD | slope |
|---|---|---|---|---|---|
| all finishers | 1671 | 0.740 | 105 | 201 min | −3.23 min/pt |
| top 500 seeds | 503 | 0.503 | 73 | 227 min | −3.12 min/pt |
| top 200 seeds | 200 | 0.406 | 54 | **175 min** | −2.69 min/pt |

R² falls because the predictor's spread collapses (105 → 54), not because the relationship weakens.
In absolute terms the **top 200 are the most predictable subgroup in the field** (residual SD 175 min vs 201 overall), and the slope is near-stable. So "small differences in rating no longer separate runners" is not what these numbers show.

**Fix:** remove the claim

---

## B. Methodology

**B1. The Voza group's "median index 781" is the wrong population.** 781 is the median of the **155 DNFs** in that group; the **446 runners ahead of him** have a median of **758**. The sentence's "they" points at the 446. (758 vs the field's 558 is still a strong contrast — just use the right number)

**B2. The rest regressions are cut-off censored at the slow end.** 228 finishers land within 2.5 h of the 46h30 limit, 96 within 1.5 h. Mean rest by finishing band peaks at 1251–1500 (243 min) then *falls* to 205 — the report reads this correctly as cut-off pressure, but then pools those same runners into every rest regression. **Fix:** add the <44 h sensitivity fit (it strengthens the result, see A2).

**B3. "Had he rested around the group median, he would have finished higher" is a counterfactual the data cannot support** — and it sits one section from the report's own correct caveat that heavy resters also move more slowly at equal ability (partial r = 0.276). Rest is not free time you can subtract. Fix: rewrite the claim to give his ranking on moving time

---

## C. Presentation

- **Course length is stated three different ways in the repo:** "175 km" in this report's prose, 173.6 km in `R/checkpoints.R`, 171 km in `CLAUDE.md`. Pick one and source it.
- "31% versus 22%" is hardcoded twice (values check out: 30.9 / 21.8) in a document that is otherwise inline-R throughout.
- **Duplication with `blowup_pacing.qmd`.** The whole "Early pace and DNF risk" section reproduces  what the companion report exists to do — and it recomputes overpace with a *different recipe*  (raw-hours residual here, median-normalised residual there). They agree numerically on this data, but there are now two definitions of "overpace" in the repo that can silently diverge.
  **Fix:** delete this section
- The ±15 neighbour bar chart with 31 rotated x-labels is hard to read; a dot plot ordered by rest, with Tangi flagged, would carry the same point.
- The plotly slider figure is the main reason this file renders to ~17 MB. Worth asking whether it earns that over the static banded chart directly above it.
  Fix: there is a difference between the first 150 and the 151 to 200 seeds. So let's just add one static figure with band of 50 for runner up to the seed 250, and highlight where Tangi stands in the graph. 

---

## D. Complementary analyses

1. **Per-aid-station rest — the strongest untapped dataset you have.**
   `passings.rest_time_seconds` is populated on **16,086 rows** and is used nowhere:

   | aid station | n | median stop |
   |---|---|---|
   | Champex-Lac (sortie) | 1779 | **38.8 min** |
   | Courmayeur (sortie) | 2091 | **32.7 min** |
   | Vallorcine (sortie) | 1694 | 16.0 min |
   | Trient | 1726 | 15.8 min |
   | La Fouly | 1799 | 11.4 min |
   | Les Contamines | 1506 | 11.2 min |
   | Les Chapieux | 2274 | 10.6 min |

   Where does the rest budget actually go, and does *when* you spend it (front-loaded vs back-loaded) predict the finish at equal ability? This is a direct extension of the report's own question and needs no new scraping.

2. **Sex and index calibration — never touched.** F 35.7% DNF vs M 28.6%; 55–59M 48.3%; 40–44W 43.9%. Is the index→time line the same slope *and* intercept by sex? That's a genuinely interesting question and one interaction term away.

3. **Replace the three-tab R² comparison with a calibration curve.** Fit index→time with a spline and plot residual SD by index decile. That answers A4 properly and is more honest than comparing R² across nested range-restricted subsets.
