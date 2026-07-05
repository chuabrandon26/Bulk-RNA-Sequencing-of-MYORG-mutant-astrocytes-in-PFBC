library(fgsea)
library(ggplot2)
library(dplyr)
library(readxl)


gmt.file <- "C:/Users/chuab/Desktop/DEG_Lab_Rotation/Lab_Rotation_scripts/GSEA_R_script/mh.all.v2024.1.Mm.symbols.gmt" #change the name

#get the name of pathways
pathways <- gmtPathways(gmt.file)
#str(head(pathways));length(pathways)

# List of file names to process
files_list <- c("WT_SFM_vs_WT_SCM_Cx.xlsx", 
                "WT_SFM_vs_WT_SCM_CB.xlsx", 
                "HOM_SFM_vs_WT_SFM_Cx.xlsx", 
                "HOM_SFM_vs_WT_SFM_CB.xlsx", 
                "HOM_SFM_vs_HOM_SCM_Cx.xlsx", 
                "HOM_SFM_vs_HOM_SCM_CB.xlsx", 
                "HOM_SCM_vs_WT_SFM_Cx.xlsx", 
                "HOM_SCM_vs_WT_SFM_CB.xlsx", 
                "HOM_SCM_vs_WT_SCM_Cx.xlsx", 
                "HOM_SCM_vs_WT_SCM_CB.xlsx",
                "WT_SFM_Cx_vs_WT_SFM_CB.xlsx",
                "WT_SCM_Cx_vs_WT_SCM_CB.xlsx")

# Loop over each file in the list
for (current_file in files_list) {
  
  # Reading the file (differential expression analysis)
  current_marker_expr_df <- readxl::read_xlsx(paste0("C:/Users/chuab/Desktop/DEG_Lab_Rotation/Combined_data/Sequenced_data/", current_file))
  
  # Remove duplicates based on SYMBOL and select the one with the highest AveExpr
  current_marker_expr_df <- current_marker_expr_df %>%
    group_by(SYMBOL) %>%
    filter(AveExpr == max(AveExpr, na.rm = TRUE)) %>%
    ungroup()
  
  # Remove rows where SYMBOL is NA
  current_marker_expr_df <- current_marker_expr_df %>% filter(!is.na(SYMBOL))
  
  #(calculating the rank)
  current_marker_expr_df$comb_val <- sign(current_marker_expr_df$logFC) * -log10(current_marker_expr_df$P.Value)#adjust the names
  
  #creating the rank vector
  current_marker_expr_df <- current_marker_expr_df %>% mutate(rank = rank(comb_val, ties.method = "random")) %>%
    arrange(desc(rank))
  ranks <- current_marker_expr_df$comb_val
  names(ranks) <- current_marker_expr_df$SYMBOL
  ranks <- ranks[!(is.infinite(ranks) | is.na(ranks))]
  
  set.seed(42)
  
  #performing gsea
  fgseaRes <- fgsea::fgsea(pathways, ranks, minSize = 10, maxSize = Inf, scoreType = "std", nproc = 1)
  
  #filtering for the statistically significant pathways
  gsea_sig <- fgseaRes[fgseaRes$padj < 0.05,]
  
  # Adjusting the file names for the output
  current_file_filtered <- gsub(".xlsx", "", current_file)  # Remove file extension for naming
  ggplot_title <- paste0("Gene Set Enrichment analysis on ", current_file_filtered)
  file_name <- paste0('GSEA_hallmark_', current_file_filtered, '.png')  # Prefixing with GSEA_hallmark_
  
  # Extract relevant columns without the leadingEdge
  gsea_sig_df <- gsea_sig[, c("pathway", "NES", "pval", "padj", "size")]
  
  # Save the GSEA results as CSV
  gsea_results_file <- paste0("C:/Users/chuab/Desktop/DEG_Lab_Rotation/Lab_Rotation_scripts/GSEA_R_script/GSEA_results_", current_file_filtered, ".csv")
  write.csv(gsea_sig_df, gsea_results_file, row.names = FALSE)
  
  # Creating a figure
  gsea_plot <- ggplot(gsea_sig, aes(x = NES, y = pathway, color = pval, size = size)) + 
    geom_point(stat = 'identity') + 
    xlab("NES") + ylab("Pathways") + ggtitle(ggplot_title) + 
    theme_bw() + 
    theme(
      axis.text = element_text(face = "bold", size = 18),  # Adjusting size of axis text to 18 for better fitting
      plot.title = element_text(face = "bold", size = 30),
      axis.text.y = element_text(size = 14)  # Specifically adjust the y-axis text size if needed
    )
  
  # Print the plot to check if it displays on screen (optional)
  print(gsea_plot)
  
  # Saving the plot to the file
  file_path <- paste0(getwd(), "/GSEA_hallmark_", current_file_filtered, ".png")  # Saving with the prefix "GSEA_hallmark_"
  ggsave(file_path, plot = gsea_plot, width = 26, height = 10)
  
  # Enrichment plot (example, modify with your actual data if necessary)
  plotEnrichment(examplePathways[["5991130_Programmed_Cell_Death"]],
                 exampleRanks) + labs(title = paste("Programmed Cell Death", current_file_filtered))
}








# =========================================
# Updated Script with explicit NES legend clarification
# =========================================

library(ggplot2)
library(dplyr)

# List of files with GSEA results
files_list <- c("WT_SFM_vs_WT_SCM_Cx.xlsx", 
                "WT_SFM_vs_WT_SCM_CB.xlsx",
                "WT_SFM_Cx_vs_WT_SFM_CB",
                "WT_SCM_Cx_vs_WT_SCM_CB",
                "HOM_SFM_vs_WT_SFM_Cx.xlsx", 
                "HOM_SFM_vs_WT_SFM_CB.xlsx", 
                "HOM_SFM_vs_HOM_SCM_Cx.xlsx", 
                "HOM_SFM_vs_HOM_SCM_CB.xlsx", 
                "HOM_SCM_vs_WT_SFM_Cx.xlsx", 
                "HOM_SCM_vs_WT_SFM_CB.xlsx", 
                "HOM_SCM_vs_WT_SCM_Cx.xlsx", 
                "HOM_SCM_vs_WT_SCM_CB.xlsx")

# Initialize an empty data frame to store combined results
combined_results <- data.frame()

# Loop through each condition and extract the NES and pathways from the GSEA results
for (current_file in files_list) {
  
  # Construct the file name for the GSEA results CSV based on the current condition
  gsea_file <- paste0("C:/Users/chuab/Desktop/DEG_Lab_Rotation/Lab_Rotation_scripts/GSEA_R_script/GSEA_results_", 
                      gsub(".xlsx", "", current_file), ".csv")
  
  # Load the GSEA results CSV for the current condition
  gsea_results <- read.csv(gsea_file)
  
  # Ensure that the relevant columns (NES and pathway) are present
  if (!all(c("NES", "pathway") %in% colnames(gsea_results))) {
    stop("NES and pathway columns are missing in the GSEA results!")
  }
  
  # Add the condition name (from the current file)
  gsea_results$condition <- gsub(".xlsx", "", current_file)  # Remove file extension to use as condition name
  
  # Combine this result with the combined results
  combined_results <- rbind(combined_results, gsea_results)
}

# Check if combined results contain data
if (nrow(combined_results) == 0) {
  stop("No data was combined. Check if the GSEA results files are correctly loaded.")
}

# Prepare the data for plotting
combined_results$NES_color <- ifelse(combined_results$NES > 0, "blue", "red")  # Color based on NES value
combined_results$Absolute_NES <- abs(combined_results$NES)   # Size of dots based on the absolute NES value

# Generate the combined dot plot
dot_plot <- ggplot(combined_results, aes(x = condition, y = pathway, color = NES_color, size = Absolute_NES)) +
  geom_point() + 
  scale_color_manual(values = c("blue" = "blue", "red" = "red"), 
                     name = "NES Sign", 
                     labels = c("Negative NES", "Positive NES")) +  # Clarify what red/blue represents
  labs(title = "GSEA Enrichment Scores for Combined Pathways Across Conditions", 
       x = "Condition", 
       y = "Pathways") + 
  theme_bw() +
  theme(axis.text = element_text(face = "bold", size = 10),   # Reduce text size for x-axis
        plot.title = element_text(face = "bold", size = 20),
        axis.text.y = element_text(size = 12),
        axis.text.x = element_text(angle = 45, hjust = 1)) +  # Rotate x-axis labels for better readability
  scale_size_continuous(range = c(2, 10)) +  # Control the size range of the dots
  theme(legend.position = "top") # Move the legend to the top to make it more visible

  
# Save the combined dot plot
ggsave("C:/Users/chuab/Desktop/DEG_Lab_Rotation/Lab_Rotation_scripts/GSEA_R_script/combined_dotplot.png", 
       plot = dot_plot, 
       width = 26, height = 10, dpi = 300)

# Optional: Print a message to confirm the plot was saved successfully
cat("Combined dot plot saved successfully as 'combined_dotplot.png'.")

# Save the combined GSEA results used in the dot plot to an Excel file
library(writexl)

output_excel_file <- "C:/Users/chuab/Desktop/DEG_Lab_Rotation/Lab_Rotation_scripts/GSEA_R_script/combined_GSEA_results.xlsx"
writexl::write_xlsx(combined_results, output_excel_file)

cat("Combined GSEA results exported successfully to 'combined_GSEA_results.xlsx'.")

