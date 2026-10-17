library(sf)
library(dplyr)

saps <- read.csv("data/raw/SAPS_2022_CSOED3270923.csv", check.names = FALSE)
eds  <- st_read("data/raw/ed_boundaries.gpkg", quiet = TRUE)

dublin_counties <- c("DUBLIN CITY", "DUN LAOGHAIRE/RATHDOWN", "FINGAL", "SOUTH DUBLIN")
age_cols <- grep("^T1_1AGE([0-9]|1[0-4])[MF]$", names(saps), value = TRUE)

saps_ind <- saps |>
  transmute(
    GUID,
    children_0_14 = rowSums(across(all_of(age_cols))),
    unemployed    = T8_1_LFFJT + T8_1_STUT + T8_1_LTUT,
    labour_force  = T8_1_WT + unemployed,
    low_edu       = T10_4_NFT + T10_4_PT + T10_4_LST,
    edu_stated    = T10_4_TT - T10_4_NST,
    lone_parent   = T4_3FOPMCT + T4_3FOPFCT,
    families_kids = T4_3FCCT + lone_parent
  ) |>
  mutate(
    unemp_rate    = ifelse(labour_force > 0, unemployed / labour_force, NA),
    low_edu_share = ifelse(edu_stated > 0, low_edu / edu_stated, NA),
    lone_share    = ifelse(families_kids > 0, lone_parent / families_kids, NA)
  )

dub <- eds |>
  filter(COUNTY_ENGLISH %in% dublin_counties) |>
  left_join(saps_ind, by = c("ED_GUID" = "GUID")) |>
  mutate(
    z_unemp = as.numeric(scale(unemp_rate)),
    z_edu   = as.numeric(scale(low_edu_share)),
    z_lone  = as.numeric(scale(lone_share)),
    deprivation_z = (z_unemp + z_edu + z_lone) / 3
  )

dir.create("data/processed", showWarnings = FALSE)
saveRDS(dub, "data/processed/dublin_ed_deprivation.rds")