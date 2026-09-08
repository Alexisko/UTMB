#!/usr/bin/env Rscript

# Scrape the FULL field of a PAST UTMB edition (finishers AND DNFs) for the
# cross-year comparison. Same approach as R/scrape_all_runners.R, but the
# edition is chosen by year (the X-Tenant header) so we can pull 2024 / 2025
# alongside the 2026 data already on disk.
#
# The ranking endpoint returns finishers only, so to get DNFs we enumerate bib
# numbers against /runners/{bib}. Every starter carries a UTMB Index, a status
# and (partial) checkpoint splits.
#
# Usage:
#   Rscript R/scrape_history.R 2025            # full field, bibs 1..2750
#   Rscript R/scrape_history.R 2024 1 60       # test: bibs 1..60
#
# Writes:
#   data/processed/runners_all_utmb_<year>.csv    one row per starter
#   data/processed/passings_all_utmb_<year>.csv   one row per starter x checkpoint
#
# NB the `pointId` scheme is NOT shared across editions (2024/2025 use one
# numbering, 2026 another), so `R/checkpoints.R` does not transfer. Section
# distance is instead reconstructed from the data itself -- see
# `derive_checkpoints()` in R/checkpoints.R.

suppressPackageStartupMessages({
  library(httr2)
  library(dplyr)
  library(purrr)
  library(readr)
  library(stringr)
})

base_url  <- "https://utmblive-api.utmb.world"
race      <- "utmb"
req_per_s <- 8
max_bib_default <- 3200L   # UTMB 2024 assigned bibs above 2750; 3200 covers the field

processed_dir <- "data/processed"

utmb_request <- function(path, tenant) {
  request(base_url) |>
    req_url_path_append(path) |>
    req_headers(`X-Tenant` = tenant) |>
    req_user_agent("utmb-2026-analysis (research; https://live.utmb.world)") |>
    req_retry(max_tries = 4, backoff = \(i) 2^i) |>
    req_throttle(rate = req_per_s)
}

hms_to_seconds <- function(x) {
  if (is.null(x) || is.na(x) || !nzchar(x)) return(NA_real_)
  parts <- as.numeric(str_split_1(x, ":"))
  sum(parts * 60^rev(seq_along(parts) - 1))
}

status_to_outcome <- function(s) {
  dplyr::case_when(
    s == "f"  ~ "Finisher",
    s %in% c("a", "hd") ~ "DNF",
    .default = "Other"
  )
}

fetch_bib <- function(bib, tenant) {
  resp <- utmb_request(str_glue("runners/{bib}"), tenant) |>
    req_error(is_error = \(resp) FALSE) |>
    req_perform()
  if (resp_status(resp) != 200) return(NULL)
  d <- resp_body_json(resp, simplifyVector = FALSE)

  info <- d$resume$info %||% NULL
  if (is.null(info) || is.null(info$fullname)) return(NULL)   # unassigned bib

  res <- d$resume
  rk  <- res$ranking %||% list()
  det <- d$detail %||% list()
  passings <- det$passings %||% list()

  timed <- keep(passings, \(p) !is.null(p$timeSeconds))
  last_point <- if (length(timed)) timed[[length(timed)]]$pointId else NA_integer_

  # Bibs are shared across all races in an edition (CCC, OCC, ...). Keep only
  # the ones whose runner belongs to the UTMB race itself.
  if (!identical(res$raceId %||% NA_character_, "utmb")) return(NULL)

  runner <- tibble(
    bib          = bib,
    race_id      = res$raceId %||% NA_character_,
    fullname     = info$fullname %||% NA_character_,
    sex          = info$sex %||% NA_character_,
    age          = info$age %||% NA_integer_,
    category     = info$category %||% NA_character_,
    country_code = info$countryCode %||% NA_character_,
    club         = info$club %||% NA_character_,
    utmb_index   = info$index %||% NA_integer_,
    status       = res$status %||% NA_character_,
    outcome      = status_to_outcome(res$status %||% NA_character_),
    is_finisher  = res$isFinisher %||% NA,
    rank_scratch = rk$scratch %||% NA_integer_,
    rank_sex     = rk$sex %||% NA_integer_,
    rank_cat     = rk$category %||% NA_integer_,
    race_time    = res$raceTime %||% NA_character_,
    race_time_seconds = det$raceTimeInSeconds %||% hms_to_seconds(res$raceTime %||% NA_character_),
    total_rest_time_seconds = det$totalRestTimeSeconds %||% NA_real_,
    last_point_id = last_point,
    n_passings   = length(timed),
    start_time   = res$start %||% NA_character_
  )

  passings_tbl <- map(passings, \(p) tibble(
    bib               = bib,
    point_id          = p$pointId %||% NA_integer_,
    rank              = p$rank %||% NA_integer_,
    rank_diff         = p$rankDiff %||% NA_integer_,
    datetime_in       = p$datetimeIn %||% NA_character_,
    datetime_out      = p$datetimeOut %||% NA_character_,
    cumulated_time    = p$cumulatedTime %||% NA_character_,
    split_time        = p$time %||% NA_character_,
    split_time_seconds = p$timeSeconds %||% NA_real_,
    pace              = p$pace %||% NA_real_,
    speed             = p$speed %||% NA_real_,
    rest_time_seconds = p$restTimeSeconds %||% NA_real_
  )) |> list_rbind()

  list(runner = runner, passings = passings_tbl)
}

main <- function(year, bib_from = 1L, bib_to = max_bib_default) {
  tenant <- str_glue("utmb_{year}")
  dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
  bibs <- seq.int(bib_from, bib_to)
  message(str_glue("[{tenant}] scanning bibs {bib_from}..{bib_to} ({length(bibs)} requests)..."))

  results <- bibs |>
    map(\(b) {
      r <- fetch_bib(b, tenant)
      if (b %% 200 == 0) message(str_glue("  [{year}] ...bib {b}"))
      r
    }) |>
    compact()

  runners  <- map(results, "runner") |> list_rbind()
  passings <- map(results, "passings") |> list_rbind()

  out_r <- file.path(processed_dir, str_glue("runners_all_utmb_{year}.csv"))
  out_p <- file.path(processed_dir, str_glue("passings_all_utmb_{year}.csv"))
  write_csv(runners,  out_r)
  write_csv(passings, out_p)

  message(str_glue("[{year}] outcome tally:"))
  print(count(runners, outcome))
  message(str_glue(
    "[{year}] done. {nrow(runners)} starters, {nrow(passings)} passings -> {out_r}"))
}

if (sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 1) stop("Usage: Rscript R/scrape_history.R <year> [bib_from] [bib_to]")
  year     <- as.integer(args[[1]])
  bib_from <- if (length(args) >= 2) as.integer(args[[2]]) else 1L
  bib_to   <- if (length(args) >= 3) as.integer(args[[3]]) else max_bib_default
  main(year, bib_from, bib_to)
}
