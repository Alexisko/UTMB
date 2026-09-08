# Review — `analysis/blowup_pacing.qmd`

*Fast starts and blow-ups at the 2026 UTMB.* Review date 2026-09-07. Every number below was
recomputed from `data/processed/runners_all_utmb.csv` + `passings_all_utmb.csv`.

**Overall.** The framing is genuinely good: measuring pace *relative to the rating*, cutting by
ability band, and letting the answer be "it depends" is the right instinct, and the
protective-fast-start result in the sub-600 band is large, monotone and robust (OR 0.64–0.76,
p < 1e-6 — this one is real and under-sold). Three things need fixing before the piece stands up:
one section is a measurement artifact, the headline significance claim is selected from eight
tests, and one descriptive sentence is contradicted by the data.

---

## A. Blocking — changes a stated conclusion

### A1. "Finishers don't fade — the strong speed up" is a scale artifact

`split_ratio = rel_late / rel28`, where each `rel` is a time divided by the **finisher median at
that leg**. But the two legs do not have the same spread: among finishers,
`sd(log(front)) = 0.171` and `sd(log(late)) = 0.219` — the back half is **28% more dispersed**.
Dividing both by a median therefore does *not* put them on a common scale, and a runner who holds
*exactly* the same relative standing in both halves gets a split ratio that drifts with ability:

| Runner's standing (log-z, both halves identical) | Mechanical split ratio |
|---|---|
| z = −2 (very fast) | **0.886** |
| z = −1 | 0.929 |
| z = 0 (median) | 0.975 |
| z = +1 | 1.023 |
| z = +2 (very slow) | 1.074 |

The chart's observed band medians are **0.989 / 0.961 / 0.880 / 0.856** — essentially that null
curve. Confirmations: `cor(split_ratio, front-half time) = +0.196` (a scale-free fade measure
should be ~uncorrelated with speed), and on a proper scale-free measure — Δz = z(log late) −
z(log front) — the gradient **vanishes and stops being monotone**: −0.078 / +0.031 / −0.120 /
−0.074.

So "the elite negative-split hardest (median 0.86)" is measuring the width of the late-leg
distribution, not the elite.

- **Fix:** replace the ratio with `Δz = z(log(c200 - c28)) - z(log(c28))`, or fit
  `lm(log(late) ~ log(front) + band)` and read the band coefficients.
- **Consequence:** the honest finding becomes *"no band systematically fades or gains once the
  widening spread is accounted for"* — still a good myth-adjacent result, and it does **not**
  damage the section's real argument, which rests on cause-of-DNF (100% voluntary abandons above
  600), not on fade. Rewrite the title; keep the "ambition, not collapse" conclusion.
- **Also:** `coord_cartesian(ylim = c(0.8, 1.05))` truncates the axis on a ratio chart whose
  reference is 1, visually amplifying the artifact. Whatever replaces it should start at the
  reference line.

### A2. The headline 700–800 result is selected from eight tests

Four bands × two checkpoints = 8 logistic slopes, and the text explicitly picks the checkpoint that
maximises the effect ("The tertile gradient is steepest read here"). Adjusted:

| Band | CP | n | OR | 95% CI | p | Holm | BH |
|---|---|---|---|---|---|---|---|
| <600 | Voza | 1485 | 0.76 | 0.68–0.85 | 1.9e-06 | 1.4e-05 | 7.7e-06 |
| 600–700 | Voza | 528 | 1.08 | 0.87–1.35 | 0.52 | 1.00 | 0.82 |
| **700–800** | **Voza** | **220** | **1.51** | **1.08–2.21** | **0.023** | **0.136** | **0.061** |
| 800+ | Voza | 135 | 1.05 | 0.75–1.48 | 0.78 | 1.00 | 0.83 |
| <600 | Contamines | 1475 | 0.64 | 0.57–0.72 | 2.3e-13 | 1.8e-12 | 1.8e-12 |
| 600–700 | Contamines | 526 | 1.02 | 0.83–1.28 | 0.83 | 1.00 | 0.83 |
| 700–800 | Contamines | 220 | 1.28 | 0.93–1.82 | 0.144 | 0.72 | 0.29 |
| 800+ | Contamines | 136 | 0.93 | 0.66–1.31 | 0.69 | 1.00 | 0.83 |

The 700–800 result does not survive correction (Holm p = 0.14). n = 220 with 58 DNFs. The section
title "**The penalty is real and significant only in the 700–800 band**" and "Only the 700–800 band
clears the bar" overstate what one uncorrected p = 0.023 out of eight can carry.

- **Fix (preferred):** the claim is actually *"the effect reverses as ability rises"* — so test that
  directly with one model, `glm(dnf ~ ns(index, 4) * overpace, binomial)`, and report the
  interaction. It is far better powered than four separate slopes and it is the hypothesis you
  actually have.
- **Fix (minimum):** declare Voza the primary readout up front (not after seeing it wins), report
  the adjusted p, and soften to "the only band where the interval excludes 1 before adjustment; it
  does not survive correction for the eight band × checkpoint tests."
- The <600 result survives anything you throw at it — lead with that.

### A3. "Where runners stop is similar across bands" is false

Kruskal-Wallis on distance-at-DNF by band: **χ² = 24.5, p = 1.9e-05**.

| Band | n DNF | median km | IQR | share dropping before Courmayeur (81 km) |
|---|---|---|---|---|
| <600 | 481 | 81.3 | 67.8–99.4 | 33% |
| 600–700 | 106 | 104.0 | 81.3–127.5 | 22% |
| 700–800 | 58 | 104.0 | 81.3–127.5 | 21% |
| 800+ | 66 | 81.3 | 67.8–114.0 | 30% |

It is a **U-shape**, and it is a better story than "similar": the elite and the weakest both bail
early (elites at Courmayeur once the result is gone; the weakest under cut-off pressure), while the
middle bands grind on to Grand Col Ferret and Champex.

- **Fix:** replace the sentence with the actual finding, and change the histogram from counts with
  `scales = "free_y"` to **shares/density**. Four independent y-axes make the bands
  non-comparable — which is almost certainly how "similar" slipped through in the first place.

---

## B. Methodology — worth fixing, doesn't overturn the piece

**B1. The residualisation leaves index structure inside "overpace."** Within-band
`cor(overpace, index)`: 800+ = **−0.48** (Voza) / **−0.51** (Contamines); <600 = −0.14 / −0.11.
And the global `rel ~ index` relation is significantly cubic (cubic term F = 55.9, p = 1.1e-13). So
a linear residual is misspecified, and inside the elite band "fast start" substantially means
"lower index within the band" — which directly undermines "flat and high whatever the pacing" for
800+. **Fix:** residualise on a spline (`lm(rel ~ splines::ns(index, 4))`), then *verify and report*
that `cor(overpace, index) ≈ 0` inside every band.

**B2. The median normalisation is a no-op where the text says it matters.** `rel = c / med_fin$m`
divides by a constant, and residualising on the index afterwards makes `overpace4`/`overpace10`
exactly proportional to the raw-time residual. So "divided by the finisher-median time there (to
remove the course profile)" does nothing for the DNF analysis — it only bites in `split_ratio`.
Worse, the divisor is a **finisher** median applied to a quantity used on DNFs. Either say plainly
that it is a rescaling for readability, or drop it from the overpace path.

**B3. Reverse causation is acknowledged in one line and never probed.** It's the piece's main
threat and it deserves a test. Cheap version: refit the 700–800 slope restricted to DNFs occurring
**after Courmayeur**. If the effect is concentrated in early drops, "already struggling at 14.5 km"
beats "blew up later" as an explanation.

**B4. No data-quality accounting.** 2,382 of 2,467 scraped rows are used; 65 "Other" plus
NA-index runners vanish silently. One line in Method notes.

---

## C. Presentation

- **The 600–700 bullet is the only hardcoded stat in an otherwise fully inline-R document** —
  "Fast starters in this band have a 25% DNF rate compared to 20% overall" (actual: 24.6% fast
  tertile, 20.0% band). It also **contradicts the Summary**, which says "No clear pacing effect."
  The tertiles there are non-monotone (18.2 / 15.4 / 24.6, n≈175 each), so the Summary is right —
  delete the body claim.
- "nearly one in two" for 800+ (48.5%) — make it inline like everything else.
- The tertile chart's **title is the article's conclusion and is identical on both tabs**, while the
  two tabs show different numbers. Give each tab a title describing what *that* readout shows.
- `sprintf("p=%.2f")` in `fig-or` prints **"p=0.00"** for the <600 band. Use a floor
  (`format.pval(p, eps = 0.001)`).
- `date: "2026-09-04"` is hardcoded; the other two reports use `date: today`.
- The `dnf_where` join uses `last_point_id`, which is the last point *with a time* — worth a note
  that a runner who checks in but is not timed is attributed to the previous point.

---

## D. Complementary analyses (ranked)

1. **Replicate on 2024 and 2025.** You already hold both full fields. If the 700–800 reversal
   reproduces in two independent editions, A2's multiplicity problem evaporates — this is by far
   the strongest single move available. *Blocker:* `R/scrape_history.R` writes only `runners_*`;
   it needs the passings block from `scrape_all_runners.R` added (~30 lines) to give you splits.
2. **One continuous model instead of four bar charts.** `glm(dnf ~ ns(index,4) * overpace)` plotted
   as a predicted-DNF heatmap over (index, overpace). Shows the reversal continuously instead of
   through arbitrary cuts at 600/700/800, and fixes A2 at the same time.
3. **Discrete-time hazard model.** You have 706 DNFs across 24 distinct last-checkpoints and a
   52,692-row person-checkpoint panel. Model per-section DNF hazard on *running* overpace up to
   that section + section difficulty. This answers "*when* does a fast start catch up with you",
   which the current cross-sectional design structurally cannot.
4. **Competing risks.** The logistic models pool abandons and cut-offs, which are different
   processes. Refit separately: the <600 protective effect is very likely mostly the cut-off
   channel — which would *test* the "banks cut-off margin" claim that is currently asserted.
5. **Night exposure.** 39% of checkpoint crossings fall between 22:00 and 06:00, and runners meet
   the two nights at different points depending on pace. Does reaching Courmayeur before or after
   dark shift the hazard at equal ability? `datetime_in` is populated on all 52,692 timed rows.
6. **Sex and age — completely untouched.** F 35.7% DNF vs M 28.6%; 55–59M at 48.3%; 40–44W at
   43.9%. Does the pacing reversal hold within sex?
