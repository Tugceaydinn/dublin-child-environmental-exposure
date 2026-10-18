library(sf)
library(lme4)
library(spdep)

dub <- readRDS("data/processed/dublin_ed_final.rds")
m_log <- lmer(log1p(green_urban_pct) ~ deprivation_z + (1 | CSO_LEA),
              data = st_drop_geometry(dub))

nb <- poly2nb(dub, queen = TRUE)
lw <- nb2listw(nb, style = "W", zero.policy = TRUE)
moran <- moran.test(resid(m_log), lw, zero.policy = TRUE)
print(moran)