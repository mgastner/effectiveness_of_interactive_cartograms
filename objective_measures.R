library(rstatix)  # For pipe-friendly versions of hypothesis tests
library(tidyverse)

# Import data.
obj_meas <-
  read_csv("interactive_cartogram_objective_measures.csv",
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
cat("\nError rates by task type and interactive-feature combination:\n")
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
cat("\nError rates - main effect (Cochran's Q test):\n")
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
map_dfr(task_types, calc_error_rate_stat_main_effect) %>%
  print()

# Statistics of error rates: post-hoc tests.
cat("\nError rates - significant post-hoc McNemar tests:\n")
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
    filter(p.adj.signif != "ns") %>%
    mutate(task_type = task_type_input) %>%
    select(task_type, group1, group2, p, p.adj, p.adj.signif)
}
map_dfr(task_types, calc_error_rate_stat_post_hoc) %>%
  print()
rm(formula_for_error_rate_stat,
   mean_error_rate,
   calc_error_rate_stat_main_effect,
   calc_error_rate_stat_post_hoc)

# Summarize response times in tabular form.
correct_response <-
  obj_meas %>%
  filter(answer_is_correct)
cat("\nResponse times by task type and interactive-feature combination ")
cat("(mean, median):\n")
correct_response %>%
  group_by(task_type, interactive_feature) %>%
  summarize(mean = mean(response_time), median = median(response_time)) %>%
  mutate(mean_median = str_c("(",
                             round(mean, 1) %>% format(nsmall = 1),
                             ", ",
                             round(median, 1) %>% format(nsmall = 1),
                             ")")) %>%
  select(-c(mean, median)) %>%
  pivot_wider(names_from = interactive_feature,
              values_from = mean_median) %>%
  print()

# Statistics of response times: main effect.
cat("\nResponse times - main effect (Kruskal-Wallis test):\n")
calc_response_time_stat_main_effect <- function(task_type_input) {
  correct_response %>%
    filter(task_type == task_type_input) %>%
    kruskal_test(response_time ~ interactive_feature) %>%
    mutate(task_type = task_type_input) %>%
    select(task_type, statistic, df, p)
}
map_dfr(task_types, calc_response_time_stat_main_effect) %>%
  print()

# Statistics of error rates: post-hoc tests.
cat("\nResponse times - significant post-hoc Mann-Whitney U tests:\n")
calc_response_time_stat_post_hoc <- function(task_type_input) {
  correct_response %>%
    filter(task_type == task_type_input) %>%
    pairwise_wilcox_test(response_time ~ interactive_feature) %>%
    filter(p.adj.signif != "ns") %>%
    mutate(task_type = task_type_input) %>%
    select(task_type, group1, group2, p, p.adj, p.adj.signif)
}
map_dfr(task_types, calc_response_time_stat_post_hoc) %>%
  print()
rm(task_types,
   calc_response_time_stat_main_effect,
   calc_response_time_stat_post_hoc)
