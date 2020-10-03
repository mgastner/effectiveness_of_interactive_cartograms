# effectiveness_of_interactive_cartograms

Data and R scripts used in the article *Task-Based Effectiveness of Interactive Contiguous Area Cartograms* by Ian K. Duncan, Shi Tingsheng, Simon T. Perrault, and Michael T. Gastner (2020, under review).

Data:

- questionnaire.pdf
- interactive_cartogram_participant_info.csv
    * `participant_id`: integer between 1 and 55
    * `age`: in years (integers)
    * `gender`:
        + "Male"
        + "Female"
        + "Other"
        + "Prefer not to say".
    * `education`:
        + "High School graduate"
        + "Some college"
        + "Associate’s and/or Bachelor’s degree"
        + "Bachelor’s degree"
        + "Master’s degree"
        + "Doctorate or Professional degree"
    * `familiar_with_interactive_graphics`:
        + "Very unfamiliar"
        + "Unfamiliar"
        + "Somewhat familiar"
        + "Familiar"
        + "Very familiar"
    * `familiar_with_cartogram`:
        + "Very unfamiliar"
        + "Unfamiliar"
        + "Somewhat familiar"
        + "Familiar"
        + "Very familiar"
    * `find_birthplace`: "Consider the world map above. Would you be able to
      point at the location where you were born?"
        + "Yes, with confidence"
        + "Yes, with a little effort"
        + "Yes, with much effort"
        + "Possibly, but I’m uncertain"
        + "No"
    * `look_up_on_map`: "When you encounter the names of unfamiliar locations
      (e.g. countries, islands, lakes), how frequently do you immediately look
      them up on a map to find out where they are?"
        + "Never"
        + "Rarely"
        + "Sometimes"
        + "Generally"
        + "Always"
- interactive_cartogram_objective_measures.csv
    * `participant_id`: matches participant ID in
      interactive_cartogram_participant_info.csv
    * `question`: integer, matches question number in questionnaire.pdf
    * `task_type`: 
        + "Cluster"
        + "Compare"
        + "Detect Change"
        + "Filter"
        + "Find Adjacency"
        + "Find Top"
        + "Recognize"
        + "Summarize"
    * `interactive_feature`: 
        + "None"
        + "CSA" (cartogram-switching animation)
        + "LB" (linked brushing)
        + "IT" (infotips)
        + "All"
    * `answer_is_correct`: TRUE or FALSE
    * `response_time`: in seconds
    * `participant_uses_animation`: TRUE, FALSE or NA.
      The value is TRUE if and only if animation is available (i.e. if
      `interactive_feature` equals "CSA" or "All") and the participant played
      the animation.
- interactive_cartogram_subjective_measures.csv
    * `participant_id`: matches participant ID in
      interactive_cartogram_participant_info.csv
    * `interactive_feature`: 
        + "CSA" (cartogram-switching animation)
        + "LB" (linked brushing)
        + "IT" (infotips)
    * `phrase_pair`:
        + "Difficult to use - Easy to use"
        + "Does not form immediate impression - Forms immediate impression"
        + "Conventional - Innovative"
        + "Redundant - Informative"
        + "Hindering - Helpful"
        + "Boring - Entertaining"
        + "Ugly - Elegant"
    * `rating`: integer between 1 (worst) and 5 (best)

Required software for computer code: R and RStudio

- Open effectiveness_of_interactive_cartograms.Rproj with RStudio.
- If necessary, install `tidyverse` and `rstatix` libraries by running the R
  console commands `install.packages("tidyverse")` and
  `install.packages("rstatix")`.
- From the console, run `source("objective_measures.R")` and
  `source("subjective_measures.R")`.
  
Code was tested with this software:

```
> sessionInfo()
R version 4.0.2 (2020-06-22)
Platform: x86_64-apple-darwin17.0 (64-bit)
Running under: macOS Catalina 10.15.6

Matrix products: default
BLAS:   /System/Library/Frameworks/Accelerate.framework/Versions/A/Frameworks/vecLib.framework/Versions/A/libBLAS.dylib
LAPACK: /Library/Frameworks/R.framework/Versions/4.0/Resources/lib/libRlapack.dylib

locale:
[1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

loaded via a namespace (and not attached):
[1] compiler_4.0.2   assertthat_0.2.1 cli_2.0.2        tools_4.0.2     
[5] glue_1.4.1       rstudioapi_0.11  crayon_1.3.4     fansi_0.4.1     
[9] packrat_0.5.0 
```

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.4064663.svg)](https://doi.org/10.5281/zenodo.4064663)


