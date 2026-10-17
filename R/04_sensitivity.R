library(sf)
library(dplyr)
library(lme4)

dub <- readRDS("data/processed/dublin_ed_final.rds")
dub$ed_km2 <- as.numeric(st_area(dub)) / 1e6
d <- st_drop_geometry(dub)

get_est <- function(m) {
  ci <- confint(m, parm = "beta_", method = "Wald")
  data.frame(est = unname(fixef(m)["deprivation_z"]),
             lo  = ci["deprivation_z", 1],
             hi  = ci["deprivation_z", 2])
}

d_nopp <- d |> filter(ED_ENGLISH != "PHOENIX PARK")

res <- bind_rows(
  green_urban = bind_rows(
    base         = get_est(lmer(green_urban_pct ~ deprivation_z + (1 | CSO_LEA), data = d)),
    no_phoenix   = get_est(lmer(green_urban_pct ~ deprivation_z + (1 | CSO_LEA), data = d_nopp)),
    log1p_outcome = get_est(lmer(log1p(green_urban_pct) ~ deprivation_z + (1 | CSO_LEA), data = d)),
    adj_area     = get_est(lmer(green_urban_pct ~ deprivation_z + log(ed_km2) + (1 | CSO_LEA), data = d)),
    .id = "model"),
  green_blue = bind_rows(
    base         = get_est(lmer(green_blue_pct ~ deprivation_z + (1 | CSO_LEA), data = d)),
    no_phoenix   = get_est(lmer(green_blue_pct ~ deprivation_z + (1 | CSO_LEA), data = d_nopp)),
    log1p_outcome = get_est(lmer(log1p(green_blue_pct) ~ deprivation_z + (1 | CSO_LEA), data = d)),
    adj_area     = get_est(lmer(green_blue_pct ~ deprivation_z + log(ed_km2) + (1 | CSO_LEA), data = d)),
    .id = "model"),
  .id = "outcome")

print(as.data.frame(res), digits = 3)