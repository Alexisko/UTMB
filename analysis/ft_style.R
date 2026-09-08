# ---------------------------------------------------------------------------
# ft_style.R — a Financial Times–inspired look for the UTMB charts.
#
# Sourced by the Quarto reports. Provides:
#   * the FT colour constants (paper, ink, claret, blue, teal, ...)
#   * theme_ft()               — a flush-left, salmon-paper ggplot theme
#   * scale_{colour,fill}_ft() — the FT categorical palette
#   * ft_source()              — a standard "Source / Chart" caption
#   * ft_diverging / ft_sequential gradient helpers
#   * ft_plotly()              — apply the paper + fonts to a plotly object
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(ggplot2)
  library(ggtext)
})

# --- Palette ----------------------------------------------------------------
# An original editorial scheme (warm ivory paper, petrol-blue primary) — the
# refinement of an FT-style page without copying its salmon-and-claret livery.
# Variable NAMES are kept stable so every chart re-colours from here alone.
ft_paper   <- "#F4F1E9"  # warm ivory paper
ft_paper2  <- "#EAE4D7"  # a shade down, for panels / fills
ft_ink     <- "#21201C"  # near-black for text
ft_ink2    <- "#6B655C"  # muted ink for secondary text / axes
ft_grid    <- "#E1DBCE"  # gridline on ivory
ft_rule    <- "#21201C"  # baseline / top rule

ft_blue    <- "#1F5A73"  # petrol blue — primary accent
ft_claret  <- "#A6462E"  # terracotta — "slower" / abandon / high band
ft_teal    <- "#2C8375"  # teal — "faster" / good
ft_orange  <- "#CE7A2C"  # ochre — warm secondary
ft_purple  <- "#5B4B7A"
ft_green   <- "#3F7A52"
ft_gold    <- "#B6892F"

# Categorical order for series.
ft_cat <- c(ft_blue, ft_claret, ft_teal, ft_orange, ft_purple, ft_green, ft_gold)

# Semantic colours reused across the two reports.
ft_highlight <- ft_ink       # the "spotlight runner" mark
ft_faster    <- ft_teal      # ran faster than expected (good)
ft_slower    <- ft_claret    # ran slower than expected
ft_neutral   <- "#B0A695"    # a warm grey that reads on ivory

# --- ggplot theme -----------------------------------------------------------
# base_family defaults to Helvetica Neue (present on macOS); FT charts are set
# in a humanist sans, titles bold and flush-left, subtitle carrying the point.
theme_ft <- function(base_size = 13, base_family = "Helvetica Neue") {
  half <- base_size / 2
  theme_minimal(base_size = base_size, base_family = base_family) %+replace%
    theme(
      # paper
      plot.background  = element_rect(fill = ft_paper, colour = NA),
      panel.background = element_rect(fill = ft_paper, colour = NA),
      # grid: horizontal only, understated
      panel.grid.major.y = element_line(colour = ft_grid, linewidth = 0.4),
      panel.grid.major.x = element_blank(),
      panel.grid.minor   = element_blank(),
      # a real baseline, FT-style
      axis.line.x  = element_line(colour = ft_rule, linewidth = 0.5),
      axis.ticks.x = element_line(colour = ft_rule, linewidth = 0.4),
      axis.ticks.length.x = unit(3, "pt"),
      axis.ticks.y = element_blank(),
      axis.text  = element_text(colour = ft_ink2, size = rel(0.85)),
      axis.title = element_text(colour = ft_ink2, size = rel(0.85)),
      axis.title.x = element_text(margin = margin(t = half), hjust = 0),
      axis.title.y = element_text(margin = margin(r = half), angle = 90, hjust = 1),
      # title block: flush to the far left of the whole plot
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      plot.title = element_textbox_simple(
        family = base_family, face = "bold", colour = ft_ink,
        size = rel(1.18), lineheight = 1.05, margin = margin(b = 3)),
      plot.subtitle = element_textbox_simple(
        family = base_family, colour = ft_ink2,
        size = rel(0.92), lineheight = 1.25, margin = margin(b = half)),
      plot.caption = element_textbox_simple(
        family = base_family, colour = ft_ink2, size = rel(0.72),
        lineheight = 1.2, margin = margin(t = half + 2)),
      # legend
      legend.title = element_text(colour = ft_ink2, size = rel(0.82)),
      legend.text  = element_text(colour = ft_ink2, size = rel(0.82)),
      legend.key.height = unit(12, "pt"),
      legend.position = "right",
      # facets
      strip.text = element_text(colour = ft_ink, face = "bold",
                                size = rel(0.9), hjust = 0,
                                margin = margin(b = 4, t = 2)),
      plot.margin = margin(10, 14, 8, 8)
    )
}

# --- Scales -----------------------------------------------------------------
scale_colour_ft <- function(...) ggplot2::scale_colour_manual(..., values = ft_cat)
scale_color_ft  <- scale_colour_ft
scale_fill_ft   <- function(...) ggplot2::scale_fill_manual(..., values = ft_cat)

# Diverging: teal (below / faster) — salmon-grey (on schedule) — claret (above / slower).
scale_colour_ft_div <- function(name = NULL, midpoint = 0, ...) {
  ggplot2::scale_colour_gradient2(
    low = ft_teal, mid = ft_neutral, high = ft_claret,
    midpoint = midpoint, name = name, ...)
}
scale_color_ft_div <- scale_colour_ft_div

# Sequential single-hue (petrol blue), for an ability/strength ramp.
scale_colour_ft_seq <- function(name = NULL, ...) {
  ggplot2::scale_colour_gradient(low = "#C6D6DD", high = ft_blue, name = name, ...)
}
scale_color_ft_seq <- scale_colour_ft_seq

# --- Caption / source line --------------------------------------------------
ft_source <- function(note = NULL, editions = "2026 edition") {
  base <- paste0("Source: UTMB Live API, ", editions, ". Chart: Alexis Konarski")
  if (is.null(note)) base else paste0(note, "  ·  ", base)
}

# --- plotly ----------------------------------------------------------------
# Re-skin an interactive plotly object with the FT paper, fonts and ink.
ft_plotly <- function(p) {
  plotly::layout(
    p,
    paper_bgcolor = ft_paper, plot_bgcolor = ft_paper,
    font = list(family = "Helvetica Neue, Helvetica, Arial, sans-serif",
                color = ft_ink, size = 13),
    xaxis = list(gridcolor = ft_grid, zerolinecolor = ft_grid,
                 linecolor = ft_rule, tickcolor = ft_rule),
    yaxis = list(gridcolor = ft_grid, zerolinecolor = ft_grid),
    legend = list(bgcolor = "rgba(0,0,0,0)")
  )
}
