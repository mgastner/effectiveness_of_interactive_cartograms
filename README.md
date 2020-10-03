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
- From the console, run `source("objective_measures.R")` and
  `source("subjective_measures.R")`.

[![DOI](https://zenodo.org/badge/264931474.svg)](https://zenodo.org/badge/latestdoi/264931474)
