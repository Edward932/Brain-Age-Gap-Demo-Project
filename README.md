# Brain Age Gap Demo (MRI summaries)

This repo contains a small demo project that predicts chronological age from MRI-derived summary measures (~1400 features), computes brain age gap (BAG = predicted age − true age), applies an age-bias calibration step, and tests whether walking endurance (2-minute walk distance) is associated with calibrated BAG after adjusting for covariates.

**Recommended Use**

See `BAG_Summary.pdf` for a short, report-like summary and explanation of the project. Then download and open `BAG_Pipeline.html` in your browser to view the R pipeline, since GitHub may not display the file properly in-browser. If you would like to run the code yourself, clone the repo and follow the guide below.

**Main artifacts**
- `BAG_Summary.pdf` — short results summary
- `BAG_Pipeline.html` - pre-rendered HTML report (synthetic data and opens without running code)
- `BAG_Pipeline.Rmd` — reproducible pipeline (synthetic data by default but can be run with real data - instructions below)

## Guide To Run BAG_Pipeline.Rmd
This guide is only for `BAG_Pipeline.Rmd`. `BAG_Summary.pdf` and `BAG_Pipeline.html` don't require running any code.
1. Install dependencies (recommended):
   - `install.packages("renv")`
   - `renv::restore(prompt = FALSE)`
2. Knit `BAG_Pipeline.Rmd` to HTML.

By default the pipeline uses synthetic data (no DUA data required). To run on real data, set `USE_SYNTHETIC_DATA <- FALSE` after following the instructions below.

**Runtime note:** `FAST_MODE <- TRUE` loads cached XGBoost CV results to keep knitting fast. Set `FAST_MODE <- FALSE` to recompute XGBoost CV (may take a few minutes).

## Outputs
Knitting `BAG_Pipeline.Rmd` produces an HTML report with model performance plots (Elastic Net and XGBoost), a partial-effect plot for 2-minute walk distance, and a small effect-size table.

## Notes on data access (real data)
Raw AABC files are not included due to a data-use agreement. Access typically requires creating a BALSA account and accepting the AABC terms.

To access real data:
1. Go to https://balsa.wustl.edu/ and create an account.
2. Navigate to Aging Adult Brain Connectome (AABC) Release 2: https://balsa.wustl.edu/project?project=AABC2
3. Download:
   - `AABC_Release2_Non-imaging_Data-XL.csv`
   - `AABC_Release2_StructuralIDPs.zip`
4. Unzip `AABC_Release2_StructuralIDPs.zip`.
5. Place the files in this repo as:
   - `AABC_Data/AABC_Release2_Non-imaging_Data-XL.csv`
   - `AABC_Data/` *(all CSV files from the unzipped StructuralIDPs folder)*

Then:
- Set `USE_SYNTHETIC_DATA <- FALSE`
- Knit `BAG_Pipeline.Rmd` again (may take a few minutes)

## Methods (high level)
- Elastic net (`cv.glmnet`) with out-of-fold predictions for age.
- XGBoost (`xgb.cv`) with cached CV results in `FAST_MODE`.
- Age-bias calibration: linear fit of predicted age ~ true age on out-of-fold predictions, then rescaling predictions to match the identity line.
- Downstream association: multivariable linear regression of calibrated BAG on 2-minute walk distance, adjusting for age, sex, BMI, education, and sitting SBP.

## Reproducibility
Seeds are set within the Rmd. Package versions are locked with `renv.lock`.
