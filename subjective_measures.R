install.packages("install.load", repos = "http://cran.rstudio.com")
library(install.load)
install_load("Biobase",  # For openPDF()
             "dplyr",  # For data wrangling
             "ggplot2",  # For plotting
             "ggstance",  # For geom_linerangeh()
             "grid",  # For segmentsGrob()
             "purrr",  # For functional programming
             "readr",  # For read_csv()
             "stringr",  # For str_replace()
             "tidyr")  # For pivoting

interactive_feature_levels <- c("CSA", "LB", "IT")
subj_meas_long <- read_csv("interactive_cartogram_subjective_measures.csv",
                           col_types = cols()) %>%
  mutate(phrase_pair = factor(phrase_pair),
         phrase_pair_id = as.numeric(phrase_pair),
         interactive_feature =
           factor(interactive_feature, levels = interactive_feature_levels))
n_phrase_pairs <-
  subj_meas_long$phrase_pair %>%
  unique() %>%
  length()

# Calculate the grand mean defined as the mean of all responses, regardless
# of interactive feature, conditioned on the phrase pair
summary_by_phrase_pair <-
  subj_meas_long %>%
  group_by(phrase_pair) %>%
  summarise(grand_mean = mean(rating), .groups = "drop")

# Summarize subjective measures in tabular form
cat("\nMean user ratings:\n")
subj_meas_summary <-
  subj_meas_long  %>%
  group_by(phrase_pair, interactive_feature) %>%
  summarise(mean = mean(rating),
            .groups = "drop") %>%
  inner_join(summary_by_phrase_pair, by = "phrase_pair") %>%
  pivot_wider(names_from = interactive_feature,
              values_from = mean) %>%
  arrange(desc(grand_mean)) %>%
  select(-grand_mean, everything()) %>%
  rename(mean = grand_mean) %>%
  print()
cat("\n")

# Break phrase pair into negative and positive sentiment
negative <-
  subj_meas_summary %>%
  pluck("phrase_pair") %>%
  str_split(" - ") %>%
  map(`[`(1)) %>%
  str_replace("Does not form immediate impression",
              "Does not form\nimmediate\nimpression")
positive <-
  subj_meas_summary %>%
  pluck("phrase_pair") %>%
  str_split(" - ") %>%
  map(`[`(2)) %>%
  str_replace("Forms immediate impression",
              "Forms\nimmediate\nimpression")

# For some tasks below, it is easier to work with wide format
subj_meas_wide <-
  subj_meas_long %>%
  select(-phrase_pair) %>%
  pivot_wider(names_from = c(interactive_feature, phrase_pair_id),
              values_from = rating)

set.seed(-102163215)  # Fix seed for reproducability
get_bootstrap_ci <- function() {
  
  # Function that samples from the rows in "survey", assuming that the input
  # is in wide format.
  n_resample <- 10000
  resample <- function(iter) {
    if (iter %% 1000 == 0) {
      cat("Working on resample", iter, "out of", n_resample, "\n")
    }
    subj_meas_wide %>%
      sample_frac(replace = TRUE) %>%
      summarise_at(-1, mean)
  }
  map_dfr(seq_len(n_resample), resample)
}

# Extract the 2.5-th and 97.5-th percentile from the bootstrap resamples
subj_meas_inference <-
  get_bootstrap_ci() %>%
  summarise_all(list(ci_lo = ~ quantile(x = ., probs = 0.025),
                     ci_hi = ~ quantile(x = ., probs = 0.975))) %>%
  pivot_longer(everything(),
               names_to = c("interactive_feature",
                            "phrase_pair_id",
                            "statistic"),
               names_pattern = "(.*)_(.)_(ci.*)") %>%
  pivot_wider(names_from = statistic) %>%
  mutate(phrase_pair_id = as.integer(phrase_pair_id))

# Join the bootstrap confidence intervals with information about the mean
# for each combination of phrase pair and interactive feature
subj_meas_summary <-
  subj_meas_summary %>%
  mutate(phrase_pair_id = as.numeric(phrase_pair),
         phrase_pair_rank = rev(seq_along(phrase_pair))) %>%
  select(-mean) %>%
  pivot_longer(names_to = "interactive_feature",
               cols = all_of(interactive_feature_levels),
               values_to = "mean") %>%
  left_join(subj_meas_inference,
            by = c("phrase_pair_id", "interactive_feature")) %>%
  mutate(interactive_feature =
           factor(interactive_feature, levels = interactive_feature_levels))

# Data frame with grid points for ggplot().
grid_points <-
  expand_grid(x = 1:5, y = seq_len(n_phrase_pairs))

# Rotate the legend symbol for the paths by 90 degress. See
# https://stackoverflow.com/questions/35703983/how-to-change-angle-of-line-in-
# customized-legend-in-ggplot2
GeomPath$draw_key <- function(data, params, size) {
  if (is.null(data$linetype)) {
    data$linetype <- 0
  } else {
    data$linetype[is.na(data$linetype)] <- 0
  }
  segmentsGrob(0.5, 0.1, 0.5, 0.9,
               gp = gpar(col = alpha(data$colour %||% 
                                       data$fill %||% "black", data$alpha),
                         lwd = (data$size %||% 0.5) * .pt,
                         lty = data$linetype %||% 1,
                         lineend = "butt"), 
               arrow = params$arrow)
}

# As of March 2020, it is not possible to have a secondary axis if the
# values are discrete. For a workaround, see
# https://stackoverflow.com/questions/45361904/duplicating-and-modifying-
# discrete-axis-in-ggplot2/45362497
ggplot(subj_meas_summary, aes(mean, phrase_pair_rank)) +
  geom_line(aes(x, y, group = y),
            grid_points,
            colour = "grey25",
            size = 0.4) +
  geom_point(aes(x, y), grid_points, size = 2) +
  geom_path(aes(colour = interactive_feature,
                linetype = interactive_feature,
                group = interactive_feature),
            size = 0.6) +
  geom_linerangeh(aes(xmin = ci_lo,
                      xmax = ci_hi,
                      colour = interactive_feature),
                  position = position_dodgev(0.25),
                  size = 1) +
  scale_y_continuous(breaks = seq_len(n_phrase_pairs),
                     labels = rev(negative),
                     sec.axis =
                       dup_axis(name = "Positive",
                                labels = rev(positive))) +
  scale_colour_brewer(name = "Interactive feature",
                      labels = c("Cartogram-\nswitching\nanimation",
                                 "Linked\nbrushing",
                                 "Infotips"),
                      palette = "Set1") +
  scale_linetype_manual(name = "Interactive feature",
                        labels = c("Cartogram-\nswitching\nanimation",
                                   "Linked\nbrushing",
                                   "Infotips"),
                        values = c("solid", "dashed", "dotted")) +
  xlim(1, 5) +
  xlab("Mean rating") +
  ylab("Negative") +
  theme_bw() +
  theme(legend.key.height = unit(1.3, "cm"),
        legend.text = element_text(margin = margin(l = -5)),
        legend.position = "top",
        panel.grid.minor = element_blank())

# Export and open plot
ggsave("subjective_measures.pdf", width = 5, height = 4.5)
openPDF("subjective_measures.pdf")
rm(list = ls())  # Clear environment