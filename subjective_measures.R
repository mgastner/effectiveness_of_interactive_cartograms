library(tidyverse)
phrase_pair_levels <- c("Difficult to use - Easy to use", 
                        "Hindering - Helpful",
                        "Redundant - Informative",
                        str_c("Does not form immediate impression - ",
                              "Forms immediate impression"),
                        "Ugly - Elegant",
                        "Boring - Entertaining",
                        "Conventional - Innovative")
cat("\nMean user ratings:\n")
read_csv("interactive_cartogram_subjective_measures.csv",
         col_types = cols()) %>%
  mutate(phrase_pair = factor(phrase_pair, levels = phrase_pair_levels),
         interactive_feature = factor(interactive_feature,
                                      levels = c("CSA", "LB", "IT"))) %>%
  group_by(phrase_pair, interactive_feature) %>%
  summarise(mean = mean(rating),
            .groups = "drop") %>%
  pivot_wider(names_from = interactive_feature,
              values_from = mean) %>%
  print()
rm(phrase_pair_levels)