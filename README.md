# Brain Age Gap Demo (MRI summaries)

This repo contains a small demo project that predicts chronological age from MRI-derived regional summary measures (~1400 features), computes brain age gap (BAG = predicted age − true age), applies an age-bias calibration step, and tests whether walking endurance (2-minute walk distance) is associated with calibrated BAG after adjusting for covariates.

**Main artifacts**
- `Bag_Summary.pdf` — short results summary
- `BrainDraft.Rmd` — reproducible pipeline (synthetic data by default)

## Quick start
1. Install dependencies (recommended):
   - `install.packages("renv")`
   - `renv::restore()`
2. Knit `BrainDraft.Rmd` to HTML.

By default the pipeline uses synthetic data (no DUA data required). Set `USE_SYNTHETIC_DATA <- FALSE` to run on real data (requires local access under DUA; see below).

## Notes on data access
Raw AABC files are not included due to a data-use agreement. To run on real data, place the required CSVs in `data/` (not tracked) and set `USE_SYNTHETIC_DATA <- FALSE`. See `DataProcessing.R` for expected filenames.

## Methods (high level)
- Elastic net (`cv.glmnet`) with out-of-fold predictions for age.
- XGBoost (`xgb.cv`) with cached CV results in FAST_MODE.
- Age-bias calibration: linear fit of predicted age ~ true age on OOF predictions and rescaling to match the identity line.
- Downstream association: multivariable linear regression of calibrated BAG on two-minute walk distance, adjusting for age, sex, BMI, education, and sitting SBP.

## Reproducibility
Seeds are set within the Rmd. Package versions are locked with `renv.lock`.
