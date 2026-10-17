library(sf)
library(dplyr)
library(tidyr)

dub <- readRDS("data/processed/dublin_ed_deprivation.rds")
f   <- list.files("data/raw", pattern = "\\.fgb$", full.names = TRUE)
ua  <- st_read(f[1], quiet = TRUE)

dub <- st_make_valid(dub)
ua  <- ua |>
  st_transform(st_crs(dub)) |>
  st_make_valid() |>
  dplyr::select(code_2018, class_2018)

ed_geom <- dub |>
  dplyr::select(ED_GUID) |>
  mutate(ed_area = as.numeric(st_area(geom_col <- st_geometry(dub))))
st_agr(ed_geom) <- "constant"
st_agr(ua)      <- "constant"

inter <- st_intersection(ed_geom, ua)
inter$piece_area <- as.numeric(st_area(inter))

shares <- inter |>
  st_drop_geometry() |>
  group_by(ED_GUID, ed_area, code_2018) |>
  summarise(a = sum(piece_area), .groups = "drop") |>
  mutate(share = a / ed_area) |>
  dplyr::select(ED_GUID, code_2018, share) |>
  pivot_wider(names_from = code_2018, values_from = share,
              names_prefix = "share_", values_fill = 0)

share_cols <- grep("^share_", names(shares), value = TRUE)
shares$ua_coverage <- rowSums(shares[, share_cols])
if (!"share_14100" %in% names(shares)) shares$share_14100 <- 0
shares$green_urban_share <- shares$share_14100

dub_exp <- dub |> left_join(shares, by = "ED_GUID")

saveRDS(dub_exp, "data/processed/dublin_ed_exposure.rds")

print(head(ua |> st_drop_geometry() |> count(code_2018, class_2018, sort = TRUE), 40))
summary(dub_exp$ua_coverage)
sum(dub_exp$ua_coverage < 0.95, na.rm = TRUE)
sum(is.na(dub_exp$ua_coverage))
summary(dub_exp$green_urban_share)