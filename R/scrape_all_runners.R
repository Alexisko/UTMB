#!/usr/bin/env Rscript

# Scrape the FULL UTMB 2026 field -- finishers AND non-finishers (DNF/cut-off).
#
# The ranking endpoint only returns finishers, so to get DNFs we enumerate bib
# numbers against /runners/{bib}. Every starter (finisher or not) carries a
# UTMB Index, a status, and partial checkpoint splits.
#
# Status codes seen: f = finisher, a = abandon (DNF), hd = hors delai (cut-off),
# s = other/started. Mapped to a coarse `outcome`: Finisher / DNF / Other.
#
# Usage:
#   Rscript R/scrape_all_runners.R              # full field, bibs 1..2750
#   Rscript R/scrape_all_runners.R 1 60         # test: bibs 1..60
#
# Writes:
#   data/processed/runners_all_utmb.csv   one row per starter
#   data/processed/passings_all_utmb.csv  one row per starter x checkpoint

suppressPackageStartupMessages({
  library(httr2)
  library(dplyr)
  library(purrr)
  library(readr)
  library(stringr)
})

base_url  <- "https://utmblive-api.utmb.world"
tenant    <- "utmb_2026"
race      <- "utmb"
req_per_s <- 8
max_bib_default <- 2750L   # highest observed bib is 2700

processed_dir <- "data/processed"

utmb_request <- function(path) {
  request(base_url) |>
    req_url_path_append(path) |>
    req_headers(`X-Tenant` = tenant) |>
    req_user_agent("utmb-2026-analysis (research; https://live.utmb.world)") |>
    req_retry(max_tries = 4, backoff = \(i) 2^i) |>
    req_throttle(rate = req_per_s)
}

# Parse "HH:MM:SS" / "H:MM:SS" -> seconds (NA-safe).
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

# Fetch one bib. Returns NULL if the bib is unassigned, else parsed lists.
fetch_bib <- function(bib) {
  resp <- utmb_request(str_glue("runners/{bib}")) |>
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

  runner <- tibble(
    bib          = bib,
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

main <- function(bib_from = 1L, bib_to = max_bib_default) {
  dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
  bibs <- seq.int(bib_from, bib_to)
  message(str_glue("Scanning bibs {bib_from}..{bib_to} ({length(bibs)} requests)..."))

  results <- bibs |>
    map(\(b) {
      r <- fetch_bib(b)
      if (b %% 200 == 0) message(str_glue("  ...bib {b}"))
      r
    }) |>
    compact()

  runners  <- map(results, "runner") |> list_rbind()
  passings <- map(results, "passings") |> list_rbind()

  write_csv(runners,  file.path(processed_dir, "runners_all_utmb.csv"))
  write_csv(passings, file.path(processed_dir, "passings_all_utmb.csv"))

  tally <- runners |> count(outcome)
  message("Outcome tally:")
  print(tally)
  message(str_glue(
    "Done. {nrow(runners)} starters, {nrow(passings)} passings -> ",
    "{processed_dir}/runners_all_utmb.csv"
  ))
}

if (sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)
  bib_from <- if (length(args) >= 1) as.integer(args[[1]]) else 1L
  bib_to   <- if (length(args) >= 2) as.integer(args[[2]]) else max_bib_default
  main(bib_from, bib_to)
}
