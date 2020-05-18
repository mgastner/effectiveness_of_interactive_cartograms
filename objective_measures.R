library(rstatix)  # For pipe-friendly versions of hypothesis tests
library(tidyverse)

# Import data.
obj_meas <- read_csv("interactive_cartogram_objective_measures.csv",
                     col_types = cols()) %>%
  mutate(interactive_feature = factor(interactive_feature,
                                      levels = c("None",
                                                 "CSA",
                                                 "LB",
                                                 "IT",
                                                 "All")))

# For later convenience, store task types in a vector.
task_types <-
  unique(obj_meas$task_type) %>%
  sort()

# Summarize error rates in tabular form.
error_rate <-
  obj_meas %>%
  group_by(task_type, interactive_feature) %>%
  summarise(perc_wrong = 100 * mean(!answer_is_correct))
cat("Error rates by task type and interactive-feature combination:\n")
error_rate %>%
  pivot_wider(names_from = interactive_feature,
              values_from = perc_wrong) %>%
  print()

# Statistics of error rates: main effect.
formula_for_error_rate_stat <-
  answer_is_correct ~ interactive_feature | participant_id
mean_error_rate <- function(task_type_input) {
  error_rate %>%
    filter(task_type == task_type_input) %>%
    summarize(mean = mean(perc_wrong)) %>%
    pluck("mean")
}
calc_error_rate_stat_main_effect <- function(task_type_input) {
  if (mean_error_rate(task_type_input) == 0.0) {
    return(NULL)
  }
  cochran_q <-
    obj_meas %>%
    filter(task_type == task_type_input) %>%
    cochran_qtest(formula_for_error_rate_stat) %>%
    mutate(task_type = task_type_input) %>%
    select(task_type, statistic, df, p)
}
cat("\nError rates - main effect (Cochran's Q test):\n")
map_dfr(task_types, calc_error_rate_stat_main_effect) %>%
  print()

# Statistics of error rates: post-hoc tests.
calc_error_rate_stat_post_hoc <- function(task_type_input) {
  if (mean_error_rate(task_type_input) == 0.0) {
    return(NULL)
  }
  pw_mc_nemar <-
    obj_meas %>%
    filter(task_type == task_type_input) %>%
    pairwise_mcnemar_test(formula_for_error_rate_stat,
                          correct = FALSE,
                          p.adjust.method = "holm") %>%
    filter(p.adj.signif != "ns")
  if (nrow(pw_mc_nemar) == 0) {
    return(NULL)
  } else {
    pw_mc_nemar %>%
      mutate(task_type = task_type_input) %>%
      select(task_type, group1, group2, p, p.adj, p.adj.signif)
  }
}
calc_error_rate_stat_post_hoc("Find Top")
cat("\nError rates - significant post-hoc McNemar tests:\n")
map_dfr(task_types, calc_error_rate_stat_post_hoc) %>%
  print()

