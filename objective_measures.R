install.packages("install.load", repos = "http://cran.rstudio.com")
library(install.load)
install_load("cowplot",  # For plot_grid()
             "dplyr",  # For data wrangling
             "ggpubr",  # For stat_pvalue_manual()
             "ggplot2",  # For plotting
             "purrr",  # For functional programming
             "readr",  # For read_csv()
             "rstatix",  # For pipe-friendly versions of hypothesis tests
             "stringr",  # For str_c()
             "tidyr")  # For pivoting

# Install Biobase to run openPDF()
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}
BiocManager::install("Biobase")
library(Biobase)

# Import data
obj_meas <-
  read_csv("interactive_cartogram_objective_measures.csv",
           col_types = cols()) %>%
  mutate(interactive_feature =
           factor(interactive_feature,
                  levels = c("None", "CSA", "LB", "IT", "All")))

# For later convenience, store task types in a vector
task_types <-
  obj_meas %>%
  pluck("task_type") %>%
  unique() %>%
  sort()

# Summarize error rates in tabular form
error_rate <-
  obj_meas %>%
  group_by(task_type, interactive_feature) %>%
  summarise(perc_wrong = 100 * mean(!answer_is_correct),
            .groups = "drop")
cat("\nError rates by task type and interactive-feature combination:\n")
error_rate %>%
  pivot_wider(names_from = interactive_feature,
              values_from = perc_wrong) %>%
  print()

# Statistics of error rates: main effect
formula_for_error_rate_stat <-
  answer_is_correct ~ interactive_feature | participant_id
mean_error_rate <- function(task_type_input) {
  error_rate %>%
    filter(task_type == task_type_input) %>%
    summarise(mean = mean(perc_wrong), .groups = "drop") %>%
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

# Statistics of error rates: post-hoc tests
cat("\nError rates - significant post-hoc McNemar tests:\n")
calc_pw_mc_nemar <- function(task_type_input) {
  pw_mc_nemar <-
    obj_meas %>%
    filter(task_type == task_type_input) %>%
    pairwise_mcnemar_test(formula_for_error_rate_stat,
                          correct = FALSE,
                          p.adjust.method = "holm")
}
calc_error_rate_stat_post_hoc <- function(task_type_input) {
  if (mean_error_rate(task_type_input) == 0.0) {
    return(NULL)
  }
  calc_pw_mc_nemar(task_type_input) %>%
    filter(p.adj.signif != "ns") %>%
    mutate(task_type = task_type_input) %>%
    select(task_type, group1, group2, p, p.adj, p.adj.signif)
}
map_dfr(task_types, calc_error_rate_stat_post_hoc) %>%
  print()

# Summarize response times in tabular form
correct_response <-
  obj_meas %>%
  filter(answer_is_correct)
cat("\nResponse times by task type and interactive-feature combination ")
cat("(mean, median):\n")
correct_response %>%
  group_by(task_type, interactive_feature) %>%
  summarise(mean = mean(response_time),
            median = median(response_time),
            .groups = "drop") %>%
  mutate(mean_median = str_c("(",
                             round(mean, 1) %>% format(nsmall = 1),
                             ", ",
                             round(median, 1) %>% format(nsmall = 1),
                             ")")) %>%
  select(-c(mean, median)) %>%
  pivot_wider(names_from = interactive_feature,
              values_from = mean_median) %>%
  print()

# Statistics of response times: main effect
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

# Statistics of error rates: post-hoc tests
cat("\nResponse times - significant post-hoc Mann-Whitney U tests:\n")
calc_pw_wilcox <- function(task_type_input) {
  correct_response %>%
    filter(task_type == task_type_input) %>%
    pairwise_wilcox_test(response_time ~ interactive_feature)
}
calc_response_time_stat_post_hoc <- function(task_type_input) {
  calc_pw_wilcox(task_type_input) %>%
    filter(p.adj.signif != "ns") %>%
    mutate(task_type = task_type_input) %>%
    select(task_type, group1, group2, p, p.adj, p.adj.signif)
}
map_dfr(task_types, calc_response_time_stat_post_hoc) %>%
  print()

plot_task_type <- function(task_type_input) {
  # Function to return a plot with two panels: a bar plot for the error rate
  # and a violin plot for the response times.
  # Argument: task_type as a string
  # Return value: ggplot object
  
  if (is.null(task_type_input)) {
    return(NULL)
  }
  chi2_and_main_p <- function(test) {
    if (test$p < 0.001) {
      bquote(chi ^ 2 == phantom(" ") * .(sprintf("%.2f", test$statistic))
             * ", " *  ~ italic(p) < 10 ^ .(ceiling(log(test$p, 10))))
    } else if (test$p < 0.01) {
      bquote(chi ^ 2 == phantom(" ") * .(sprintf("%.2f", test$statistic))
             * ", " *  ~ italic(p) < 0.01)
    } else {
      bquote(chi ^ 2 == phantom(" ") * .(sprintf("%.2f", test$statistic))
             * ", " *  ~ italic(p) == phantom(" ")
             * .(sprintf("%.2f", test$p)))
    }
  }
  if (mean_error_rate(task_type_input) == 0.0) {
    g_error <- ggdraw() +
      draw_label("No errors.\nAll tasks completed\ncorrectly.",
                 size = 16)
  } else {
    cochran_q <-
      obj_meas %>%
      filter(task_type == task_type_input) %>%
      cochran_qtest(formula_for_error_rate_stat)
    mc_nemar <-  # Heights of brackets for pairwise comparisons
      calc_pw_mc_nemar(task_type_input) %>%
      mutate(y.position = case_when(task_type_input == "Summarize" &
                                      group1 == "None" &
                                      group2 == "CSA" ~ 92,
                                    task_type_input == "Cluster" &
                                      group1 == "CSA" &
                                      group2 == "All" ~ 50,
                                    task_type_input == "Compare" &
                                      group1 == "LB" &
                                      group2 == "All" ~ 40,
                                    task_type_input == "Filter" &
                                      group1 == "LB" &
                                      group2 == "All" ~ 48,
                                    task_type_input == "Summarize" &
                                      group1 == "None" &
                                      group2 == "All" ~ 106,
                                    task_type_input == "Summarize" &
                                      group1 == "CSA" &
                                      group2 == "LB" ~ 101,
                                    task_type_input == "Summarize" &
                                      group1 == "CSA" &
                                      group2 == "IT" ~ 87,
                                    task_type_input == "Summarize" &
                                      group1 == "LB" &
                                      group2 == "All" ~ 97,
                                    task_type_input == "Summarize" &
                                      group1 == "IT" &
                                      group2 == "All" ~ 92,
                                    TRUE ~ 0))
    
    # Get confidence intervals for error rates
    binom_test_for_interactive_feature <- function(feature) {
      obj_meas %>%
        filter(task_type == task_type_input &
                 interactive_feature == feature) %>%
        select(answer_is_correct) %>%
        summarise(n_error = sum(!answer_is_correct),
                  n_correct = sum(answer_is_correct)) %>%
        t() %>%
        binom_test() %>%
        mutate(interactive_feature = feature,
               perc_wrong = 100 * estimate,
               conf.low = 100 * conf.low,
               conf.high = 100 * conf.high)
    }
    ci <- map_dfr(obj_meas %>%
                    pluck("interactive_feature") %>%
                    unique(),
                  binom_test_for_interactive_feature)
    error_rate_for_task_type <-
      error_rate %>%
      filter(task_type == task_type_input)
    g_error <-
      ggplot(error_rate_for_task_type, aes(interactive_feature, perc_wrong)) +
      geom_col(fill = "#93a1a1") +
      geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                    data = ci,
                    width = 0.25) +
      stat_pvalue_manual(mc_nemar,
                         label = "p.adj.signif",
                         hide.ns = TRUE,
                         size = 5,
                         vjust = 0.6) +
      scale_x_discrete(limits = levels(obj_meas$interactive_feature)) +
      ylim(0, 106) +
      ggtitle("Error rate:",
              chi2_and_main_p(cochran_q)) +
      xlab("Condition") +
      ylab("Incorrect answers (%)") +
      theme_bw() +
      theme(plot.subtitle =
              element_text(size = 17, margin = margin(t = 0, b = 0)),
            plot.title =
              element_text(size = 17, margin = margin(t = 0, b = 0)),
            text = element_text(size = 15))
  }
  kruskal <-
    correct_response %>%
    filter(task_type == task_type_input) %>%
    kruskal_test(response_time ~ interactive_feature)
  wilcox <-  # Heights of brackets for pairwise comparisons
    calc_pw_wilcox(task_type_input) %>%
    mutate(y.position = case_when(task_type_input == "Compare" &
                                    group1 == "IT" &
                                    group2 == "All" ~ 105,
                                  task_type_input == "Detect Change" &
                                    group1 == "LB" &
                                    group2 == "All" ~ 95,
                                  task_type_input == "Detect Change" &
                                    group1 == "LB" &
                                    group2 == "IT" ~ 85,
                                  TRUE ~ 0))
  response_time_for_task_type <-
    correct_response %>%
    filter(task_type == task_type_input)
  g_response_time <-
    ggplot(response_time_for_task_type,
           aes(interactive_feature, response_time)) +
    geom_violin(colour = NA,
                fill = "#93a1a1",
                scale = "width") +
    geom_boxplot(lwd = 0.2,
                 outlier.alpha = 0.8,
                 outlier.size = 0.8,
                 width = 0.2) +
    stat_pvalue_manual(wilcox,
                       label = "p.adj.signif",
                       hide.ns = TRUE,
                       size = 5,
                       vjust = 0.6) +
    scale_x_discrete(limits = levels(obj_meas$interactive_feature)) +
    ylim(0, 200) +
    ggtitle("Response time:",
            chi2_and_main_p(kruskal)) +
    xlab("Condition") +
    ylab("Seconds") +
    theme_bw() +
    theme(plot.subtitle = element_text(size = 17,
                                       margin = margin(t = 0, b = 0)),
          plot.title = element_text(size = 17, margin = margin(t = 0, b = 0)),
          text = element_text(size = 15))
  title <-
    ggdraw() +
    draw_label(task_type_input,
               fontface = "bold.italic",
               size = 18) +
    theme(plot.background = element_rect(fill = "#e6e6e6", color = NA))
  bottom_row <- plot_grid(g_error, g_response_time)
  plot_grid(title,
            bottom_row,
            nrow = 2,
            rel_heights = c(0.12, 1))
}

# Create a list with the pattern of task type names and NULL that produces the
# desired plot_grid()-layout
n_cell <- 6 * ceiling(length(task_types) / 2) - 3
vector("list", 1.5 * length(task_types)) %>%
  `[<-`((rep(seq(1, n_cell, 6), each = 2) + c(0, 2))[seq_along(task_types)],
        task_types) %>%
  map(plot_task_type) %>%
  plot_grid(plotlist = .,
            ncol = 3,
            rel_widths = c(1, 0.15, 1),
            rel_heights = c(rep(c(1, 0.05), 0.5 * length(task_types) - 1), 1))

# Export and open plot
ggsave("objective_measures.pdf",
       width = 13,
       height = 18)
openPDF("objective_measures.pdf")
rm(list = ls())  # Clear environment