#!/usr/bin/env Rscript

# Scrape UTMB 2026 results from the UTMB Live API.
#
# Usage:
#   Rscript R/scrape_utmb.R            # full scrape (all finishers)
#   Rscript R/scrape_utmb.R 25         # only first 25 finishers' detail (quick test)
#
# Writes:
#   data/raw/ranking_<race>.json
#   data/processed/runners_<race>.csv
#   data/processed/passings_<race>.csv

suppressPackageStartupMessages({
  library(httr2)
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(readr)
  library(stringr)
  library(jsonlite)
})

# ---- Configuration ---------------------------------------------------------

base_url  <- "https://utmblive-api.utmb.world"
tenant    <- "utmb_2026"   # X-Tenant header selects the edition
race      <- "utmb"        # race slug within the edition
page_size <- 200L          # ranking rows per page
req_per_s <- 8             # polite request rate for per-runner detail

raw_dir       <- "data/raw"
processed_dir <- "data/processed"

# ---- Low-level request helper ---------------------------------------------

# Build a throttled, retrying request carrying the required tenant header.
utmb_request <- function(path, query = list()) {
  request(base_url) |>
    req_url_path_append(path) |>
    req_url_query(!!!query) |>
    req_headers(`X-Tenant` = tenant) |>
    req_user_agent("utmb-2026-analysis (research; https://live.utmb.world)") |>
    req_retry(max_tries = 4, backoff = \(i) 2^i) |>
    req_throttle(rate = req_per_s)
}

utmb_get_json <- function(path, query = list()) {
  utmb_request(path, query) |>
    req_perform() |>
    resp_body_json(simplifyVector = FALSE)
}

# ---- Fetch the full final ranking (finishers) -----------------------------

# Pull every page of the FINAL_RANKING and return the raw runner list.
fetch_ranking <- function() {
  first <- utmb_get_json(
    str_glue("races/{race}/progressive"),
    list(type = "FINAL_RANKING", limit = page_size, page = 0)
  )
  total  <- first$totalRunner %||% length(first$runners)
  n_page <- ceiling(total / page_size)
  message(str_glue("Ranking: {total} finishers across {n_page} page(s)."))

  rest <- seq_len(n_page - 1) |>
    map(\(p) {
      utmb_get_json(
        str_glue("races/{race}/progressive"),
        list(type = "FINAL_RANKING", limit = page_size, page = p)
      )$runners
    })

  c(first$runners, list_flatten(rest))
}

# ---- Parsers ---------------------------------------------------------------

# One ranking entry -> a single tidy row.
parse_ranking_row <- function(r) {
  info <- r$info %||% list()
  rk   <- r$ranking %||% list()
  tibble(
    bib          = r$bib %||% NA_integer_,
    fullname     = info$fullname %||% NA_character_,
    sex          = info$sex %||% NA_character_,
    age          = info$age %||% NA_integer_,
    category     = info$category %||% NA_character_,
    country_code = info$countryCode %||% NA_character_,
    club         = info$club %||% NA_character_,
    utmb_index   = info$index %||% NA_integer_,
    rank_scratch = rk$scratch %||% NA_integer_,
    rank_sex     = rk$sex %||% NA_integer_,
    rank_cat     = rk$category %||% NA_integer_,
    race_time    = r$raceTime %||% NA_character_,
    diff_to_first = r$diffToFirst %||% NA_character_,
    is_finisher  = r$isFinisher %||% NA,
    status       = r$status %||% NA_character_,
    start_time   = r$start %||% NA_character_,
    profile_url  = info$url %||% NA_character_
  )
}

# One runner-detail response -> list(runner = <1-row tibble>, passings = <tibble>).
parse_runner_detail <- function(d, bib) {
  det <- d$detail %||% list()

  runner <- tibble(
    bib                    = bib,
    race_time_seconds      = det$raceTimeInSeconds %||% NA_real_,
    total_rest_time        = det$totalRestTime %||% NA_character_,
    total_rest_time_seconds = det$totalRestTimeSeconds %||% NA_real_,
    n_passings             = length(det$passings %||% list())
  )

  passings <- map(det$passings %||% list(), \(p) {
    tibble(
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
    )
  }) |>
    list_rbind()

  list(runner = runner, passings = passings)
}

fetch_runner_detail <- function(bib) {
  parse_runner_detail(utmb_get_json(str_glue("runners/{bib}")), bib)
}

# ---- Main ------------------------------------------------------------------

main <- function(max_runners = NULL) {
  dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

  # 1. Ranking ---------------------------------------------------------------
  ranking_raw <- fetch_ranking()
  write_json(ranking_raw, file.path(raw_dir, str_glue("ranking_{race}.json")),
             auto_unbox = TRUE, null = "null")

  ranking <- map(ranking_raw, parse_ranking_row) |> list_rbind()

  # 2. Per-runner detail (splits + rest time) --------------------------------
  bibs <- ranking$bib
  if (!is.null(max_runners)) bibs <- head(bibs, max_runners)
  message(str_glue("Fetching detail for {length(bibs)} runner(s)..."))

  details <- bibs |>
    map(\(b) {
      res <- fetch_runner_detail(b)
      if (match(b, bibs) %% 100 == 0) message(str_glue("  ...{match(b, bibs)}/{length(bibs)}"))
      res
    })

  runner_detail <- map(details, "runner") |> list_rbind()
  passings      <- map(details, "passings") |> list_rbind()

  # 3. Join and write --------------------------------------------------------
  runners <- ranking |>
    left_join(runner_detail, by = join_by(bib))

  runners_path  <- file.path(processed_dir, str_glue("runners_{race}.csv"))
  passings_path <- file.path(processed_dir, str_glue("passings_{race}.csv"))
  write_csv(runners, runners_path)
  write_csv(passings, passings_path)

  message(str_glue(
    "Done.\n  {nrow(runners)} runners -> {runners_path}\n",
    "  {nrow(passings)} passings -> {passings_path}"
  ))
}

# ---- Entry point -----------------------------------------------------------

if (sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)
  max_runners <- if (length(args) >= 1) as.integer(args[[1]]) else NULL
  main(max_runners)
}
