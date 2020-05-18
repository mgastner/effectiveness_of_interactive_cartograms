library(tidyverse)
obj_meas <- read_csv("interactive_cartogram_objective_measures.csv",
                     col_types = cols()) %>%
  mutate(interactive_feature = factor(interactive_feature,
                                      levels = c("None",
                                                 "CSA",
                                                 "LB",
                                                 "IT",
                                                 "All")))
error_rate <-
  obj_meas %>%
  group_by(task_type, interactive_feature) %>%
  summarise(perc_wrong = 100 * mean(!answer_is_correct)) %>%
  pivot_wider(names_from = interactive_feature,
              values_from = perc_wrong)
cat("Error rates by task type and interactive-feature combination:")
print(error_rate)