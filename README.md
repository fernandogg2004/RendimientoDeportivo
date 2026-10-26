# LaLiga expected goals — regression, ANOVA and ANCOVA with full model diagnostics

A Python scraping/ETL pipeline that builds a match-level LaLiga dataset from FBref, followed by an
R analysis that explains each team's expected goals (xG) in a match from team and opponent
profiles, tests for home advantage and checks whether attacking metrics translate into xG
differently at home and away.

## The problem

Football commentary takes home advantage and "attacking quality" for granted. This project asks
how much of a team's match xG can be explained by simple season-level team and opponent profiles,
whether home advantage in xG is statistically detectable, and whether the relationship between
attacking metrics and xG changes with venue — while checking, rather than assuming, the
assumptions behind the linear-model inference.

## At a glance

| | |
|---|---|
| **Data** | FBref LaLiga fixtures (match xG) and squad statistics, scraped with `pandas.read_html`; one row per team per match |
| **Methods** | OLS with VIF analysis and AIC stepwise selection; one-way ANOVA on venue; ANCOVA with and without venue × covariate interactions; residual, leverage and Cook's-distance diagnostics; Shapiro–Wilk, Breusch–Pagan, Harrison–McCabe, Ramsey RESET, Levene and per-team Durbin–Watson tests; refits without outliers |
| **Main findings** (as recorded in `script.R`) | Teams generate on average **0.27–0.42 more xG per match at home** (ANOVA, adjusted R² 0.047); a venue × attacking-metric interaction model is preferred over the additive ANCOVA (F-test p ≈ 3·10⁻⁴) |
| **Caveat** | Normality, homoscedasticity and independence are **rejected** by the diagnostics, so p-values and intervals are approximate; see *Limitations* |
| **Status** | Completed exploratory statistics project. Data are not included, so results are not reproducible from this repository alone |

## Results

These values are written in the analysis comments of `script.R`; the dataset they were computed on
is not committed, so they **were not re-run** for this README.

| Question | Result | Method |
|---|---|---|
| Is mean xG higher at home? | Yes: difference of 0.27–0.42 xG per match (95% Tukey HSD interval); p < 2.2·10⁻¹⁶ | One-way ANOVA, `xG ~ venue` |
| How much variance does venue alone explain? | Adjusted R² = 0.047 | Same model |
| Do continuous attacking metrics add information beyond venue? | Yes (p < 2.2·10⁻¹⁶) | F-test, ANOVA vs ANCOVA |
| Do slopes differ between home and away? | Interaction model preferred (p ≈ 3·10⁻⁴) | F-test, additive vs interaction ANCOVA |
| Are OLS assumptions met? | Linearity accepted (RESET p = 0.37); normality (Shapiro–Wilk p < 2.2·10⁻¹⁶), homoscedasticity (Breusch–Pagan p ≈ 7·10⁻¹⁰) and independence (Durbin–Watson, rejected for all teams but one) **not met** | Residual diagnostics; unchanged after removing outliers |

The stepwise model retains five predictors: own possession, own goals per match, own assists per
match, opponent saves per match and goal-creating actions conceded by the opponent (all VIF < 2.5).

## Data and provenance

- **Source:** [FBref](https://fbref.com/en/comps/12/La-Liga-Stats) LaLiga pages — *Scores & Fixtures*
  (match xG) and squad / opponent statistics tables (standard, goalkeeping, shooting, goal and shot
  creation). FBref data are subject to Sports Reference's
  [data-use terms](https://www.sports-reference.com/data_use.html); the raw data are not
  redistributed here.
- **Seasons:** the scripts currently request 2023-24, 2024-25 and 2025-26. The R analysis
  describes its data as "the last two seasons", so the published results were computed on an
  earlier, two-season version of the dataset.
- **Unit of observation:** each match appears twice (once per team, with a home/away indicator).
- **Team profiles:** squad statistics are combined across seasons with a fixed weighted average
  (`Medias_ponderadas.py`) and attached to every match of that team, together with the opponent's
  profile.

## Methodology

1. `Partidos.py` — scrape fixtures, keep match xG, reshape to one row per team-match → `Partidos.csv`.
2. `Datos por equipo.py` — scrape squad and opponent tables per season, derive per-match rates
   (e.g. goals per shot, shot distance converted to metres), fill missing penalty stats with 0,
   apply the weighted average → `DatosEquipos.csv`.
3. `Obtencion de los datos.py` — join own and opponent profiles to every team-match →
   `Datos_partidos.xlsx`.
4. `script.R` — exploratory plots, OLS + collinearity treatment, diagnostics, ANOVA, ANCOVA with
   interactions, and validation of each model (comments in Galician).

## Limitations

- **Explanatory, not predictive.** Team profiles are season aggregates that include the very
  matches being explained (the initial full model even includes the final league rank), so the models
  describe associations; they say nothing about out-of-sample forecasting.
- **Dependent observations.** Two rows per match and repeated observations of the same teams
  violate independence (confirmed by the Durbin–Watson tests); together with non-normal,
  heteroscedastic residuals, the reported p-values and intervals are optimistic. Cluster-robust
  standard errors or a mixed model (team and match effects) would be the natural next step.
- **Weighting scheme.** With three seasons the weights are 0.29 (most recent), 0.45 (middle) and
  0.26 (oldest), so the middle season dominates. The two-season branch intended to give 0.7 to
  2025-26 never triggers (`"2025-2026" in grupo["Temporada"]` tests the index, not the values), so
  every two-season team gets 0.75 / 0.25.
- **Pipeline glue.** `Obtencion de los datos.py` reads from a hard-coded local Windows path and
  writes an `.xlsx`, while `script.R` expects `Datos_Partidos.csv`; a manual conversion step is
  required. FBref table positions are hard-coded and may break if the site layout changes.

## Reproduction

```bash
pip install pandas lxml openpyxl
python Partidos.py
python "Datos por equipo.py"
# edit the input paths at the top of "Obtencion de los datos.py", then:
python "Obtencion de los datos.py"
# export Datos_partidos.xlsx to Datos_Partidos.csv (same columns)
```

```r
install.packages(c("ggcorrplot", "car", "lmtest", "sm"))
source("script.R")   # interactive: press Enter to step through the plots
```

The scraping step was not executed for this README; FBref availability and table layout should be
checked before running.

## Technologies

Python (pandas), R (`lm`, `car`, `lmtest`, `sm`, `ggcorrplot`), web scraping, linear models,
ANOVA/ANCOVA, regression diagnostics.

## Author

**Fernando González González** — [LinkedIn](https://www.linkedin.com/in/fernando-gonzalez-gonzalez-math/) ·
[GitHub](https://github.com/fernandogg2004)
