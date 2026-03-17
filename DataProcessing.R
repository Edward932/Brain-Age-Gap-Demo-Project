clean_real_data = function() {
  # Importing patient summaries
  raw_non_image_data = read.csv("AABC_Data/AABC_Release2_Non-imaging_Data-XL.csv", 
                                check.names = FALSE, 
                                stringsAsFactors = FALSE)
  
  # Col names from raw data
  id = "id - Subject ID"
  sex = "sex - Sex at birth M=Male, F=Female"
  age = "age_open - Age in years, truncated at 90.  Note that this will result in some individuals appearing to be the same age (e.g. 90) for most or all of the visits that happened several years apart."
  BMI = "bmi - Vital Signs And External Measures: Body Mass Index (BMI)"
  education = "education - Subject Registration: Education derived by combining reports from SSAGA dm15 and croms_educ (No Formal Education, Primary Level Education, Some Secondary Level Education, Secondary Level Education or Equivalent, Beyond Secondary Level Education).  See also dm15 and croms_educ."
  sitting_bp = "bp_sitting - Vital Signs And External Measures: Blood Pressure Sitting"
  two_min_walk = "tlbx_walk_2_rawscore - NIH Toolbox 2-Minute Walk Endurance Test: Distance walked in two minutes, reported in feet (and fractions thereof)"
  event = "event - Study-specific visit/event short name (V1, In-person visit 1 | V2, In-person visit 2 | V3, In-person visit 3 | V4, In-person visit 4 | F1, First followup survey one year after first in-person visit in HCA | F2, Second followup survey in HCA | F3, Third followup survey in HCA | CR, Surveys collected remotely during Covid lock-down without regard to visit timing | AF1, First followup survey one year after first in-person visit in AABC)"
  
  # Only using first in person visit so that same participant is not included multiple times
  raw_v1 = raw_non_image_data[ raw_non_image_data[[event]] == "V1", ]
  filtered_non_image = data.frame(ID = trimws(raw_v1[[id]]),
                                  sex = factor(raw_v1[[sex]]),
                                  age = raw_v1[[age]],
                                  bmi = raw_v1[[BMI]],
                                  education = factor(raw_v1[[education]]),
                                  sbp_sitting = raw_v1[[sitting_bp]],
                                  two_min_walk = raw_v1[[two_min_walk]])
  
  # Data cleaning
  filtered_non_image[filtered_non_image == ""] = NA
  filtered_non_image = na.omit(filtered_non_image)
  filtered_non_image$age[filtered_non_image$age == "90 or older"] = 90
  filtered_non_image = mutate(filtered_non_image, sbp_sitting = as.numeric(sub("/.*$", "", sbp_sitting)))
  num_cols = c("age", "bmi", "sbp_sitting", "two_min_walk")
  filtered_non_image[num_cols] = lapply(filtered_non_image[num_cols], as.numeric)
  
  # Importing MRI summary data
  raw_CAM = read.csv("AABC_Data/Cortical_Areal_Myelin.csv", 
                     check.names = FALSE, 
                     stringsAsFactors = FALSE)
  raw_CASA = read.csv("AABC_Data/Cortical_Areal_Surface_Areas.csv",
                      check.names = FALSE,
                      stringsAsFactors = FALSE)
  raw_CAT = read.csv("AABC_Data/Cortical_Areal_Thicknesses.csv",
                     check.names = FALSE,
                     stringsAsFactors = FALSE)
  raw_CAV = read.csv("AABC_Data/Cortical_Areal_Volumes.csv",
                     check.names = FALSE,
                     stringsAsFactors = FALSE)
  
  # Data cleaning
  filtered_CAM = filter(raw_CAM, grepl("_V1$", x___))
  colnames(filtered_CAM) = paste("myelin", colnames(filtered_CAM), sep = "_")
  filtered_CAM = rename(filtered_CAM, ID = myelin_x___)
  
  filtered_CASA = filter(raw_CASA, grepl("_V1$", x___))
  colnames(filtered_CASA) = paste("SA", colnames(filtered_CASA), sep = "_")
  filtered_CASA = rename(filtered_CASA, ID = SA_x___)
  
  filtered_CAT= filter(raw_CAT, grepl("_V1$", x___))
  colnames(filtered_CAT) = paste("thick", colnames(filtered_CAT), sep = "_")
  filtered_CAT = rename(filtered_CAT, ID = thick_x___)
  
  filtered_CAV = filter(raw_CAV, grepl("_V1$", x___))
  colnames(filtered_CAV) = paste("vol", colnames(filtered_CAV), sep = "_")
  filtered_CAV = rename(filtered_CAV, ID = vol_x___)
  
  merg1 = inner_join(filtered_CAM, filtered_CASA, by = "ID")
  merg2 = inner_join(filtered_CAT, filtered_CAV, by = "ID")
  merged_image_data = inner_join(merg1, merg2, by = "ID")
  filtered_image_data = na.omit(merged_image_data)
  filtered_image_data = mutate(filtered_image_data, ID = sub("_V1$", "", ID))
  
  # Adding age to MRI data for model training
  MRI_df = inner_join(filtered_image_data, filtered_non_image[c("ID", "age")], by = "ID")
  MRI_df = na.omit(MRI_df)
  
  # removing non image data that does not have corresponding MRI
  filtered_non_image = semi_join(filtered_non_image, MRI_df, by = "ID")
  
  # Orders by ID if not already aligned
  if (!all(MRI_df$ID == filtered_non_image$ID)) {
    MRI_df = MRI_df[order(MRI_df$ID), ]
    filtered_non_image = filtered_non_image[order(filtered_non_image$ID), ]
  }
  
  return(list(MRI = MRI_df, attributes = filtered_non_image))
}

generate_synthetic_data = function(n = 1147, p = 1440) {
  # Generating IDs
  ID = vector("character", n)
  for (i in 1:n) {
    ID[[i]] = paste("S", i, sep="")
  }

  # Generate attributes
  age = pmin(pmax(rnorm(n, 60, 15), 18), 90)
  bmi = pmin(pmax(rnorm(n, 28, 5), 16), 65)
  sbp_sitting = pmin(pmax(rnorm(n, 125, 15), 85), 200)
  sex = factor(sample(c("M", "F"), n, replace = TRUE, prob = c(0.45, 0.55)))
  edu_levels = c(
    "No Formal Education",
    "Primary Level Education",
    "Some Secondary Level Education",
    "Secondary Level Education or Equivalent",
    "Beyond Secondary Level Education")
  education = factor(sample(edu_levels, n, replace = TRUE,
                             prob = c(0.02, 0.10, 0.25, 0.35, 0.28)),
                      levels = edu_levels)
  
  # Walk distance: correlated with age, bmi, sex + noise
  two_min_walk = 650 - 
    2.5*(age - 60) - 
    3.0*(bmi - 28) + 
    ifelse(sex == "M", 30, 0) +
    rnorm(n, 0, 60)
  two_min_walk = pmin(pmax(two_min_walk, 200), 1000)
  
  attributes = data.frame(
    ID = ID,
    sex = sex,
    age = as.numeric(age),
    bmi = as.numeric(bmi),
    education = education,
    sbp_sitting = as.numeric(sbp_sitting),
    two_min_walk = as.numeric(two_min_walk)
  )
  
  # creating random matrix
  X = matrix(NA, nrow = n, ncol = p)
  for (col in 1:p) {
    X[,col] = rnorm(n, mean = 0, sd = 2)
  }
  
  
  # injecting age and two-min walk signal into 25 cols of the matrix
  for (col in 1:25) {
    for (i in 1:length(age)) {
      curr_age = age[[i]]
      curr_2min = two_min_walk[[i]]
      
      X[i, col] = X[i, col] + 
        (curr_age * 0.1) -
        (curr_2min * 0.002) +
        rnorm(1, 0, 2)
    }
  }

  
  MRI = data.frame(
    ID = ID,
    X,
    age = as.numeric(age)
  )
  
  # Ensure same ID order in both tables
  stopifnot(identical(MRI$ID, attributes$ID))
  
  list(MRI = MRI, attributes = attributes)
}