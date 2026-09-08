# UTMB 2026 checkpoint reference: pointId -> name, cumulative km, cumulative D+.
#
# There is no public API endpoint mapping pointId -> name/km/elevation. This table
# was read from the live runner detail page (https://live.utmb.world, runner 535),
# whose per-checkpoint ranks align exactly with the scraped `passings` pointIds.
# Cumulative distance/D+ are the course figures shown there; the 7 main aid legs
# match the official profile (173.6 km, 9 700 m+).
#
# `kind`: "start", "split" (timing point), "aid" (main aid-station entry),
# "aid_out" (aid-station exit — same km/D+ as its entry), "finish".

library(tibble)

utmb_checkpoints <- tibble::tribble(
  ~point_id, ~name,                              ~cum_km, ~cum_dplus, ~kind,
  0L,        "Chamonix (départ)",                  0.0,      0L,      "start",
  4L,        "Col de Voza",                       14.5,    898L,      "split",
  6L,        "Saint-Gervais",                     22.9,   1040L,      "split",
  10L,       "Les Contamines-Montjoie",           32.4,   1535L,      "aid",
  12L,       "La Balme",                          41.1,   2130L,      "split",
  14L,       "Refuge de la Croix du Bonhomme",    46.9,   2924L,      "split",
  16L,       "Les Chapieux",                      52.2,   2924L,      "aid",
  18L,       "Col de la Seigne",                  62.9,   3977L,      "split",
  22L,       "Lac Combal",                        67.8,   3977L,      "split",
  24L,       "Arête du Mont-Favre",               71.8,   4441L,      "split",
  26L,       "Checrouit - Maison Vieille",        76.4,   4455L,      "split",
  28L,       "Courmayeur",                        81.3,   4475L,      "aid",
  30L,       "Courmayeur (sortie)",               81.3,   4475L,      "aid_out",
  36L,       "Refuge Bertone",                    86.6,   5288L,      "split",
  38L,       "Refuge Bonatti",                    94.2,   5600L,      "split",
  40L,       "Arnouvaz",                          99.4,   5727L,      "aid",
  44L,       "Grand Col Ferret",                 104.0,   6487L,      "split",
  48L,       "La Fouly",                         114.0,   6574L,      "aid",
  51L,       "Champex-Lac",                      127.5,   7086L,      "aid",
  52L,       "Champex-Lac (sortie)",             127.5,   7086L,      "aid_out",
  56L,       "La Giète",                         138.9,   7880L,      "split",
  58L,       "Trient",                           144.0,   7943L,      "aid",
  60L,       "Les Tseppes",                      148.0,   8590L,      "split",
  62L,       "Vallorcine",                       155.3,   8734L,      "aid",
  64L,       "Vallorcine (sortie)",              155.3,   8734L,      "aid_out",
  82L,       "La Flégère",                       166.6,   9687L,      "aid",
  200L,      "Chamonix (arrivée)",               173.6,   9700L,      "finish"
)

# Per-section distance and D+ (from the previous timing point). Aid exits, which
# share their entry's km/D+, get zero-length sections.
utmb_sections <- utmb_checkpoints |>
  dplyr::mutate(
    sec_km    = round(cum_km - dplyr::lag(cum_km, default = 0), 1),
    sec_dplus = cum_dplus - dplyr::lag(cum_dplus, default = 0L)
  )

# ---------------------------------------------------------------------------
# Cross-edition checkpoint reconstruction
#
# The `pointId` scheme is NOT shared between editions: UTMB 2026 uses
# 4/6/10/.../82/200 while 2024 and 2025 use 2/3/4/.../44/144. The table above is
# therefore 2026-only, and there is no public endpoint giving names or distances
# for any edition.
#
# The passings themselves carry enough to rebuild the geometry: each row has the
# section `speed` (km/h) and the section `split_time`, so
#     section km = speed x split_time
# Taking the MEDIAN across all runners at a point averages out the 2-decimal
# rounding of `speed`, giving a stable per-edition distance table.
#
# NB `split_time_seconds` is mislabelled in the API: it holds CUMULATIVE seconds
# from the start (it equals race_time_seconds at the finish). The genuine
# per-section split is the `split_time` column (an hms). We use the latter here.

derive_checkpoints <- function(passings, min_coverage = 0.25) {
  passings |>
    dplyr::mutate(
      sec_km_i = dplyr::if_else(
        !is.na(split_time) & !is.na(speed) & speed > 0,
        speed * as.numeric(split_time) / 3600,
        NA_real_
      )
    ) |>
    dplyr::summarise(
      n_rows    = dplyr::n(),
      n_usable  = sum(!is.na(sec_km_i)),
      sec_km    = round(stats::median(sec_km_i, na.rm = TRUE), 2),
      .by       = point_id
    ) |>
    dplyr::mutate(
      coverage = n_usable / n_rows,
      # Aid-station EXIT rows (and the start) are zero-length: almost no runner
      # records a section there, and the handful that do are artefacts of a
      # missed entry timing, where the exit row carries the whole leg. Trust a
      # point's distance only when most runners actually recorded a section.
      sec_km   = dplyr::if_else(coverage >= min_coverage & is.finite(sec_km), sec_km, 0)
    ) |>
    dplyr::arrange(point_id) |>
    dplyr::mutate(cum_km = round(cumsum(sec_km), 1)) |>
    dplyr::select(point_id, n_rows, n_usable, coverage, sec_km, cum_km)
}
