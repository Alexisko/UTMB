# Review — `analysis/tangi_cross_year.qmd`

*Tangi across three UTMBs.* Review date 2026-09-07. Recomputed from `runners_all_utmb_2024.csv`,
`_2025.csv` and `runners_all_utmb.csv`.

**Overall.** The core insight is correct and worth publishing: 2026 was a deeper field above his
level (133 higher-rated finishers vs 94 and 81), so the same run is worth fewer places, and ranks
must be adjusted for field strength before they can be compared. The report is also unusually
honest about *what it is assuming* — the callout on uniform vs non-uniform course change is good
thinking.

But the central quantity it transplants — his "form", the +76 places he supposedly beat his seed
by — **is a survivorship artifact, and on a like-for-like basis he ran an average race for his
rating**. The directional conclusion survives; the reasoning given for it does not. Two further
claims (the "hard floor", the "best estimate" band) are stated more strongly than the data allows,
and one first-order bias (index scale drift between editions) is assumed away without a test.

This is the report needing the most rework of the three.

---

## A. Blocking

### A1. The transplanted "form" mixes a starters-based seed with a finishers-based rank

`seed26 = 1 + #{starters rated > 758} = 229`. `r26 = 153` **among finishers**. 711 runners are
removed from the denominator but not the numerator, so **every finisher shows positive "form" by
construction**:

- Across all 1,671 2026 finishers: mean δ = **+272**, median δ = **+249**, median ρ = **0.73**.
- Tangi: δ = +76 (**28th percentile**), ρ = 0.67 (**59th percentile**).
- Among finishers seeded 150–350 — his actual neighbourhood: median ρ = 0.65 vs his 0.67,
  **48th percentile**.

Decomposed: of the +76, **+96 places come from higher-rated runners DNF-ing**, leaving **−20**.
Like-for-like (seed and rank both among finishers) his form is **δF = −20** — he finished 20 places
*behind* his rating among those who finished. Median δF across finishers is +7.

So "He beat his 2026 seed by 76 places" and "Your instinct was right" are not supported. He ran an
average race for his rating; the +76 is attrition.

**Fix:**
- **Starter base with a DNF model.** Predict how many higher-rated runners would drop in each
  year (you have per-year DNF rates by index) and compare like with like. More work, more defensible.

### A2. The "hard floor" is not a floor

*"only 93 (2024) and 80 (2025) higher-rated runners even finished, so he essentially cannot land
back at 153rd."* Finishing rank is not bounded by higher-rated finishers.

**In 2026, 43 of the 152 finishers ahead of him (28%) were rated at or below him.** To be 153rd in
2024 he would need 59 lower-rated finishers ahead of him — out of **1,667 available**. Given 43
managed it in 2026, that is entirely possible.

**Fix:** delete the claim

### A3. Index scale drift between editions is unaccounted for, and biases everything one way

I verified the scrape returns each edition's **contemporaneous** index (only 1.3% of runners
matched across 2024/2026 carry an identical index — good, and worth stating in the report). But
that means the report drops a **2026-vintage 758** into fields rated on the **2024/2025 scale**.

Drift among returnees: **+9.9 points mean (median +8.5, n = 238) 2024→2026**, and **+12.0 mean
(median +12, n = 190) 2025→2026**. At −3.23 min/index point, 10 points ≈ **32 min** of finish time.

Effect on the answer:

| his index treated as | 2024 seed | 2025 seed | 2026 seed |
|---|---|---|---|
| 738 | 217 | 188 | 277 |
| 748 | 190 | 173 | 254 |
| **758 (as reported)** | **171** | **154** | **229** |
| 768 | 154 | 131 | 211 |

And it contaminates lens E too. The year effect is a **pure intercept shift** — the index→time
slope is essentially identical across editions (−3.203 / −3.226 / −3.233, interaction test
**p = 0.90**, which is a genuine win for the report's shape assumption and should be shown) — with
intercepts 69.6 / 69.6 / **68.5** h. That is a **66 min** gap 2024→2026, of which **~32 min could
be index inflation rather than conditions**. So potentially *half* the "2024 was a slower year"
signal is an x-axis shift, and lens E does **not** absorb it: E absorbs uniform slowdowns of
runners, not a re-scaling of the predictor.

**Caveat to state:** returnees are a selected sample (people who come back and get re-rated tend to
be improving), so +10 is an upper bound on pure scale inflation. But the report currently assumes
drift = 0, which is certainly wrong and is the *least* conservative option available.

**Fix:** 
Tangi UTMB rating was 732 on the UTMB day in 2025 so even if rating drift would be a concern, it should not affect our conclusion in this case.

### A4. The "best estimate" band is presented as an uncertainty interval and is not one

It is the min–max of three deterministic recipes sharing one input. Real uncertainty is much larger:

- **Sampling error in lens E alone** (bootstrapping both index→time fits, 400 reps):
  **106–132 for 2024**, **88–108 for 2025** — already wider than the quoted band.
- **The dominant term is ignored entirely.** Tangi's residual is **−70 min against a residual SD of
  201 min → z = −0.35**. A 0.35σ deviation measured on one race is not a stable personal trait; it
  is indistinguishable from noise. Propagated honestly, the interval covers most of the top quarter
  of the field.
- **Rank precision is illusory here anyway:** 21 finishers sit within ±15 min of his projected 2024
  time, 12 within ±15 min in 2025. A 15-minute modelling error is worth 12–21 places, so quoting
  "94th" and "125th" to the unit oversells.

**Fix:** either label the band *"spread across methods, not a confidence interval"* and add a real
one, or build it properly — bootstrap the fits × sample ε from the residual distribution
(optionally shrunk toward 0). Also drop *"The best estimate on the right is the answer to trust"*
and *"Two independent... methods"*: D and E are **not independent** — both are anchored on the same
single run and the same index.

---

## B. Methodology

**B2. Lens E fits on finishers only, and the selection differs by year** (DNF 36.0% / 33.1% /
29.8%). A harder year truncates the slow tail at the cut-off, flattening the bottom of the
index→time line and shifting the intercept — which is exactly the quantity lens E reads. 
Fix: fit over a restricted well-measured index range, or use a censored (Tobit) fit.

**B4. "2024 and 2025 were slower years" is triply confounded** — genuine conditions, index drift
(A3), and which runners finish (B2). The callout box correctly argues E handles uniform slowdowns;
it should also say what E does *not* handle.

---

## C. Presentation

- **Second-person voice** ("Your instinct was right", "The honest version of your intuition") reads
  as a private reply, while the other two reports are written as published pieces. To be fixed.
- **Lens labels jump A, B, D, E — there is no C.** Looks like a deleted lens; renumber.
- `src()` is defined locally, duplicating `ft_source()` from `ft_style.R` which the other two
  reports use. Use the shared one.
- Headline table: raw time (B) gets a column of equal visual weight to the trusted lenses, then the
  text tells the reader to distrust it. Either demote it to the methodology or mark it in the table.
- Headline table: "Best estimate" for 2026 reads "— (actual 153rd)" while the D column for 2026
  reads "153rd" — the same fact twice, in two formats.
- Depth table mixes bases without saying so: `Rated > 758 (finished)` is a finisher count,
  `Index ≥ 800/850/900` are starter counts.

---

## D. Complementary analyses (ranked)

1. **Back-test the method — by far the highest-value addition.** Take the runners who finished two
   consecutive editions, project the later result from the earlier using lenses D and E, and compare
   to what actually happened. Sample sizes are workable: **52 finished both 2025 and 2026**, **87
   both 2024 and 2026**, **65 both 2024 and 2025**. This gives you a *measured* error distribution,
   converting the fabricated band of A4 into an empirical one — and it turns an unfalsifiable
   single-case projection into a validated model. It is also the only thing that can tell you
   whether "form" (ρ, δ) is a stable personal trait at all, which both lenses assume and neither
   tests.

2. **Quantile-map the index across editions** to neutralise A3, then re-run everything. Cheap, and
   it converts the largest unquantified bias into a stated adjustment.

3. **Add a DNF model** so the seed lens can work on a consistent starters base (A1 option b):
   P(finish | index, year) → expected higher-rated finishers per year.

5. **Test the uniform-slowdown assumption explicitly** rather than asserting it. I ran it: the
   slope is stable across editions (interaction p = 0.90), so the year effect really is a clean
   intercept shift. That is a *result in the report's favour* and it belongs in the callout box
   instead of the current hand-wave.
