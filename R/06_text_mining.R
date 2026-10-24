# ==============================================================================
# AIRGUARD 360: Environmental Intelligence & Decision-Support System
# File: R/06_text_mining.R
# Purpose: Text Mining of Environmental Health Advisories, Corpus Processing & Word Clouds
# INT232 Syllabus Mapping: Unit V (Text Mining, String Functions), Unit VI (Word Cloud), Practical 11
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidytext)
  library(wordcloud)
  library(RColorBrewer)
})

#' Generate Statutory Environmental Health Advisory & Mitigation Corpus
#' 
#' @return A data frame containing structured advisory texts from CPCB and WHO guidelines
generate_advisory_corpus <- function() {
  data.frame(
    Doc_ID = 1:8,
    Category = c(
      "Good", "Satisfactory", "Moderate", "Poor", "Very Poor", "Severe",
      "Mitigation_Transport", "Mitigation_Industrial"
    ),
    Text = c(
      "Air quality is satisfactory and poses little or no risk to public health. Clean air ensures safe outdoor exercise and cardiovascular vitality.",
      "Sensitive individuals with mild respiratory allergies may experience slight irritation. Protect infants and elderly during peak morning traffic.",
      "Breathing discomfort likely in people with lung asthma heart disease. Reduce prolonged vigorous outdoor exertion. Monitor children and asthmatic patients.",
      "Breathing discomfort to most people on prolonged exposure. Significant particulate matter inhalation induces coughing and respiratory fatigue. Wear N95 respirators.",
      "Respiratory illness on prolonged exposure. Triggers acute bronchitis, chronic lung inflammation, and cardiovascular distress. Avoid all outdoor physical activity.",
      "Healthy people experience severe respiratory strain and eye irritation. Critical emergency condition. Mandate school closures, halt construction, spray water mist.",
      "Enforce odd-even vehicular restrictions, transition commercial fleets to compressed natural gas CNG, expand electric bus networks, penalize idling engines.",
      "Enforce flue gas desulfurization in thermal coal power plants. Cease heavy diesel generator sets. Implement continuous stack emission monitoring systems."
    ),
    stringsAsFactors = FALSE
  )
}

#' Mine Environmental Advisory Text and Compute Word Frequencies
#' 
#' @param corpus_df Data frame containing documents and text
#' @return A data frame of cleaned tokens, term frequencies, and proportions
mine_environmental_text <- function(corpus_df = NULL) {
  if (is.null(corpus_df)) {
    corpus_df <- generate_advisory_corpus()
  }
  
  # Base R string cleaning & regex (Unit IV & V)
  clean_text <- gsub("[[:punct:]]", " ", corpus_df$Text)
  clean_text <- gsub("[[:digit:]]", " ", clean_text)
  clean_text <- tolower(clean_text)
  corpus_df$Text_Clean <- clean_text
  
  # Unit V: Tokenization and Stopword Removal using tidytext
  data("stop_words", package = "tidytext")
  
  # Domain-specific custom stopwords
  domain_stops <- data.frame(
    word = c("due", "can", "may", "also", "per", "via", "well", "use"),
    lexicon = "custom"
  )
  all_stops <- rbind(stop_words, domain_stops)
  
  word_freqs <- corpus_df %>%
    unnest_tokens(word, Text_Clean) %>%
    anti_join(all_stops, by = "word") %>%
    count(word, sort = TRUE) %>%
    filter(nchar(word) > 2) %>%
    rename(Frequency = n) %>%
    mutate(Proportion = round(Frequency / sum(Frequency), 4))
  
  return(word_freqs)
}

#' Render Syllabus-Mandated Environmental Word Cloud (Unit VI & Practical 11)
#' 
#' @param word_freqs Word frequency data frame
#' @param max_words Maximum words to render
#' @param min_freq Minimum word frequency
render_advisory_wordcloud <- function(word_freqs, max_words = 50, min_freq = 1) {
  palette <- brewer.pal(8, "Dark2")
  
  wordcloud::wordcloud(
    words        = word_freqs$word,
    freq         = word_freqs$Frequency,
    min.freq     = min_freq,
    max.words    = max_words,
    random.order = FALSE,
    rot.per      = 0.25,
    colors       = palette,
    scale        = c(3.2, 0.6)
  )
}
