library(tidyverse)
library(patchwork)
library(Lock5withR)

plot_missing <- function(df, percent = FALSE) {
  missing_patterns <- data.frame(is.na(df)) %>%
    group_by_all() %>%
    count(name = "count", sort = TRUE) %>%
    ungroup()
  
  num_patterns <- nrow(missing_patterns)
  num_features <- ncol(missing_patterns) - 1
  
  missing_patterns$missing_pattern <- factor(as.character(c(1:num_patterns)), levels = c(1:num_patterns))
  num_feature_missing <- rowSums(missing_patterns[1:num_features])
  missing_patterns <- cbind(missing_patterns, num_feature_missing)
  
  tidypattern <- missing_patterns %>% 
    pivot_longer(!c(count, missing_pattern, num_feature_missing), 
                 names_to = "feature", 
                 values_to = "is_missing")
  
  df3 <- data.frame(feature=character(), num_rows_missing=double()) 
  
  temp <- colSums(data.frame(is.na(df)))
  for (i in c(1:length(temp))) {
    df3 <- df3 %>% add_row(feature = names(temp)[i],
                           num_rows_missing = unname(temp)[i])
  }
  
  tidypattern <- tidypattern %>% left_join(df3, by="feature")
  tidypattern <- tidypattern %>% mutate(type = case_when((is_missing==FALSE & num_feature_missing==0) ~ 'complete_case',
                                                         (is_missing==FALSE & num_feature_missing>0) ~ 'not_missing',
                                                         (is_missing==TRUE & num_feature_missing>0) ~ 'missing'))
  tidypattern$missing_pattern <- factor(tidypattern$missing_pattern, levels = c(1:num_patterns))
  
  
  annotate_x <- num_features / 2
  annotate_y <- num_patterns - as.numeric(missing_patterns$missing_pattern[which(num_feature_missing == 0)]) + 1
  
  p1 <- tidypattern %>% ggplot(aes(x = reorder(feature, -num_rows_missing), 
                                   y = fct_rev(missing_pattern), 
                                   fill = factor(type))) +
    geom_tile(color = 'white', alpha=0.8) +
    xlab("Feature") + 
    ylab("Missing Pattern") + 
    # scale_y_discrete(limits = rev(levels(missing_patterns$missing_pattern))) +
    theme_bw() +
    theme(legend.position = "none",
          axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1)) +
    scale_fill_manual(values=c("darkgrey","steelblue3", 'lightgrey')) +
    annotate(geom="text", x=annotate_x, y=annotate_y, label="Complete case")
  
  missing_patterns$complete_case <- ifelse(num_feature_missing==0, 'is_complete_case', 'not_complete_case')
  p2 <- 0
  p3 <- 0
  
  if (percent == FALSE) {
    p2 <- ggplot(missing_patterns, aes(x = fct_rev(missing_pattern), y = count, fill = complete_case)) +
      geom_col(alpha=0.8) +
      coord_flip() +
      #scale_x_discrete(limits = rev(levels(missing_patterns$missing_pattern))) +
      theme_bw() +
      theme(legend.position = "none", axis.title.y = element_blank()) +
      ylab('row count') +
      scale_fill_manual("legend", values = c('is_complete_case' = "pink3", 'not_complete_case' = "pink"))
    p3 <- ggplot(df3, aes(x = reorder(feature, -num_rows_missing), y = num_rows_missing)) +
      geom_col(fill="pink", alpha=0.8) + 
      theme_bw() +
      theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1)) +
      xlab('feature') +
      ylab('num rows missing') 
  } else {
    p2 <- ggplot(missing_patterns, aes(x = fct_rev(missing_pattern), y = (count/sum(count))*100, fill = complete_case)) +
      geom_col(alpha=0.8) +
      coord_flip() +
      #scale_x_discrete(limits = rev(levels(missing_patterns$missing_pattern))) +
      theme_bw() +
      theme(legend.position = "none", axis.title.y = element_blank()) +
      ylab('% row count') +
      scale_y_continuous(limits = c(0,100)) + 
      scale_fill_manual("legend", values = c('is_complete_case' = "pink3", 'not_complete_case' = "pink"))
    p3 <- ggplot(df3, aes(x = reorder(feature, -num_rows_missing), 
                          y = (num_rows_missing/nrow(df))*100)) +
      geom_col(fill="pink", alpha=0.8) + 
      scale_y_continuous(limits = c(0,100)) + 
      theme_bw() +
      theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1)) +
      xlab('feature') +
      ylab('% rows missing')
  }
  layout <- "
  AAAAAAAA##
  BBBBBBBBCC
  BBBBBBBBCC
  BBBBBBBBCC
  "
  
  result <- p3 + p1 + p2 + 
    plot_layout(design = layout) +
    plot_annotation(title = 'Missing Value Patterns')
  
  return (result)
}