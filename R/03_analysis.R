library(sf)
library(dplyr)
library(ggplot2)
library(lme4)

dub <- readRDS("data/processed/dublin_ed_exposure.rds")

codes <- c("14100", "31000", "32000", "40000", "50000")
cols  <- paste0("share_", codes)
cols  <- cols[cols %in% names(dub)]
dub$green_blue_share <- rowSums(st_drop_geometry(dub)[, cols, drop = FALSE])

dub$green_urban_pct <- 100 * dub$green_urban_share
dub$green_blue_pct  <- 100 * dub$green_blue_share
dub$dep_quintile    <- ntile(dub$deprivation_z, 5)   # 1 = en az yoksun, 5 = en çok

d <- st_drop_geometry(dub)

tab <- d |>
  group_by(dep_quintile) |>
  summarise(n_ed = n(),
            green_urban_pct = weighted.mean(green_urban_pct, children_0_14),
            green_blue_pct  = weighted.mean(green_blue_pct,  children_0_14),
            n_children = sum(children_0_14))
print(as.data.frame(tab))

m1 <- lmer(green_urban_pct ~ deprivation_z + (1 | CSO_LEA), data = d)
m2 <- lmer(green_blue_pct  ~ deprivation_z + (1 | CSO_LEA), data = d)
print(summary(m1))
print(summary(m2))
print(confint(m1, method = "Wald"))
print(confint(m2, method = "Wald"))

top <- d |> arrange(desc(green_urban_pct)) |>
  select(ED_ENGLISH, COUNTY_ENGLISH, green_urban_pct, children_0_14) |> head(5)
print(as.data.frame(top))

dir.create("reports", showWarnings = FALSE)
p1 <- ggplot(dub) + geom_sf(aes(fill = deprivation_z), colour = NA) +
  scale_fill_viridis_c(name = "Deprivation\n(z-score)") + theme_void()
p2 <- ggplot(dub) + geom_sf(aes(fill = green_urban_pct), colour = NA) +
  scale_fill_viridis_c(name = "Green urban\narea (%)", option = "mako", direction = -1) + theme_void()
ggsave("reports/map_deprivation.png", p1, width = 7, height = 7, dpi = 150)
ggsave("reports/map_green_urban.png", p2, width = 7, height = 7, dpi = 150)

saveRDS(dub, "data/processed/dublin_ed_final.rds")