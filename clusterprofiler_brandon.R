  library(biomaRt)
  library(org.Mm.eg.db)
  library(clusterProfiler)
  library(enrichplot)
  
  ensembl <- useMart("ensembl", dataset = "mmusculus_gene_ensembl") # For human genes
  
  find_go_terms <- function(gene_list){
    #convert gene ids to entrez id
    gene_ids <- getBM(attributes = c('mgi_symbol', 'go_id', 'entrezgene_id', 'name_1006', 'namespace_1003'),
                      filters = 'mgi_symbol',
                      values = gene_list,
                      mart = ensembl)
    
    #GO enrichment
    go_enrichment <- enrichGO(gene = unique(gene_ids$entrezgene_id),
                              OrgDb = org.Mm.eg.db,
                              ont = "ALL",
                              pAdjustMethod = "bonferroni",
                              pvalueCutoff = 0.05,
                              qvalueCutoff = 0.05,
                              readable = TRUE)
    
    #summary
    go_result_list <- head(go_enrichment)
    return(list(go_result_list = go_result_list,
                go_enrichment = go_enrichment,
                gene_ids = gene_ids))
  }
  
  
  #reading the file (differential expression analysis)
  current_marker_expr_df <- readxl::read_xlsx("C:/Users/chuab/Desktop/DEG_Lab_Rotation/Combined_data/Sequenced_data/Sig_WT_SFM_Cx_vs_WT_SFM_CB.xlsx")
  negative_genes <- current_marker_expr_df[current_marker_expr_df$logFC < 0,]
  positive_genes <- current_marker_expr_df[current_marker_expr_df$logFC > 0,]
  
  # Assuming you want to use the input file name as the pattern
  diff_expression_file_pattern <- tools::file_path_sans_ext(basename("C:/Users/chuab/Desktop/DEG_Lab_Rotation/Combined_data/Sequenced_data/Sig_WT_SFM_Cx_vs_WT_SFM_CB.xlsx"))
  
  #positive BP
  if (dim(positive_genes)[1]> 0){
    results_pos<- find_go_terms(positive_genes$SYMBOL)
    sag_pos <- data.frame(results_pos$go_enrichment)
    padj_cutoff <- 0.05 # p-adjusted threshold, used to filter out pathways
    ont_type <- 'BP' #CC, MF, BP
    target_pws_pos <- unique(sag_pos$ID[sag_pos$p.adjust < padj_cutoff & sag_pos$ONTOLOGY == ont_type]) # select only target pathways have p adjusted < 0.05 
    res_df_pos <- sag_pos[sag_pos$ID %in% target_pws_pos, ]
    write.csv(res_df_pos, paste0('Clusterprofiler_GO_', ont_type, '_', diff_expression_file_pattern, '_pos.csv'), row.names = FALSE)
  }
  
  #positive CC
  if (dim(positive_genes)[1]> 0){
    results_pos<- find_go_terms(positive_genes$SYMBOL)
    sag_pos <- data.frame(results_pos$go_enrichment)
    padj_cutoff <- 0.05 # p-adjusted threshold, used to filter out pathways
    ont_type <- 'CC' #CC, MF, BP
    target_pws_pos <- unique(sag_pos$ID[sag_pos$p.adjust < padj_cutoff & sag_pos$ONTOLOGY == ont_type]) # select only target pathways have p adjusted < 0.05 
    res_df_pos <- sag_pos[sag_pos$ID %in% target_pws_pos, ]
    write.csv(res_df_pos, paste0('Clusterprofiler_GO_', ont_type, '_', diff_expression_file_pattern, '_pos.csv'), row.names = FALSE)
  }
  
  #positive MF
  if (dim(positive_genes)[1]> 0){
    results_pos<- find_go_terms(positive_genes$SYMBOL)
    sag_pos <- data.frame(results_pos$go_enrichment)
    padj_cutoff <- 0.05 # p-adjusted threshold, used to filter out pathways
    ont_type <- 'MF' #CC, MF, BP
    target_pws_pos <- unique(sag_pos$ID[sag_pos$p.adjust < padj_cutoff & sag_pos$ONTOLOGY == ont_type]) # select only target pathways have p adjusted < 0.05 
    res_df_pos <- sag_pos[sag_pos$ID %in% target_pws_pos, ]
    write.csv(res_df_pos, paste0('Clusterprofiler_GO_', ont_type, '_', diff_expression_file_pattern, '_pos.csv'), row.names = FALSE)
  }
  
  #negative BP
  if (dim(negative_genes)[1]> 0){
    results_neg<- find_go_terms(negative_genes$SYMBOL)
    sag_neg <- data.frame(results_neg$go_enrichment)
    padj_cutoff <- 0.05 # p-adjusted threshold, used to filter out pathways
    ont_type <- 'BP' #CC, MF, BP
    target_pws_neg <- unique(sag_neg$ID[sag_neg$p.adjust < padj_cutoff & sag_neg$ONTOLOGY == ont_type]) # select only target pathways have p adjusted < 0.05 and at least 6 genes
    res_df_neg <- sag_neg[sag_neg$ID %in% target_pws_neg, ]
    write.csv(res_df_neg, paste0('Clusterprofiler_GO_', ont_type, '_', gsub("\\.csv$", "", diff_expression_file_pattern), '_neg.csv'), row.names = FALSE)
  }
  
  #negative CC
  if (dim(negative_genes)[1]> 0){
    results_neg<- find_go_terms(negative_genes$SYMBOL)
    sag_neg <- data.frame(results_neg$go_enrichment)
    padj_cutoff <- 0.05 # p-adjusted threshold, used to filter out pathways
    ont_type <- 'CC' #CC, MF, BP
    target_pws_neg <- unique(sag_neg$ID[sag_neg$p.adjust < padj_cutoff & sag_neg$ONTOLOGY == ont_type]) # select only target pathways have p adjusted < 0.05 and at least 6 genes
    res_df_neg <- sag_neg[sag_neg$ID %in% target_pws_neg, ]
    write.csv(res_df_neg, paste0('Clusterprofiler_GO_', ont_type, '_', gsub("\\.csv$", "", diff_expression_file_pattern), '_neg.csv'), row.names = FALSE)
  }
  
  #negative MF
  if (dim(negative_genes)[1]> 0){
    results_neg<- find_go_terms(negative_genes$SYMBOL)
    sag_neg <- data.frame(results_neg$go_enrichment)
    padj_cutoff <- 0.05 # p-adjusted threshold, used to filter out pathways
    ont_type <- 'MF' #CC, MF, BP
    target_pws_neg <- unique(sag_neg$ID[sag_neg$p.adjust < padj_cutoff & sag_neg$ONTOLOGY == ont_type]) # select only target pathways have p adjusted < 0.05 and at least 6 genes
    res_df_neg <- sag_neg[sag_neg$ID %in% target_pws_neg, ]
    write.csv(res_df_neg, paste0('Clusterprofiler_GO_', ont_type, '_', gsub("\\.csv$", "", diff_expression_file_pattern), '_neg.csv'), row.names = FALSE)
  }


  
  
  # Load necessary libraries
  library(dplyr)
  
  # Define the base directory containing the enrichment files
  base_dir <- "C:/Users/chuab/Desktop/DEG_Lab_Rotation/Lab_Rotation_scripts/Clusterprofiler_R_script"
  
  # Define conditions and ontologies
  conditions <- c(
    "WT_SFM_vs_WT_SCM_Cx",
    "HOM_SFM_vs_WT_SFM_Cx",
    "HOM_SFM_vs_HOM_SCM_Cx",
    "HOM_SCM_vs_WT_SFM_Cx",
    "HOM_SCM_vs_WT_SCM_Cx",
    "WT_SFM_vs_WT_SCM_CB",
    "HOM_SFM_vs_WT_SFM_CB",
    "HOM_SFM_vs_HOM_SCM_CB",
    "HOM_SCM_vs_WT_SFM_CB",
    "HOM_SCM_vs_WT_SCM_CB",
    "WT_SFM_Cx_vs_WT_SFM_CB",
    "WT_SCM_Cx_vs_WT_SCM_CB",
  )
  
  ontologies <- c("BP", "CC", "MF")
  
  # Initialize an empty list to store summary data
  summary_data <- list()
  
  # Iterate through conditions
  for (condition in conditions) {
    # Create a new row for the current condition
    condition_data <- list(condition = condition)
    
    # Iterate through ontologies
    for (ont in ontologies) {
      # Construct file paths for positive and negative enrichment results with _Sig_ in filename
      pos_file <- file.path(base_dir, paste0("Clusterprofiler_GO_", ont, "_Sig_", condition, "_pos.csv"))
      neg_file <- file.path(base_dir, paste0("Clusterprofiler_GO_", ont, "_Sig_", condition, "_neg.csv"))
      
      # Check if the positive file exists and count rows
      if (file.exists(pos_file)) {
        pos_data <- tryCatch(read.csv(pos_file), error = function(e) NULL)
        pos_count <- if (!is.null(pos_data)) nrow(pos_data) else 0
      } else {
        message("File not found: ", pos_file)
        pos_count <- 0
      }
      
      # Check if the negative file exists and count rows
      if (file.exists(neg_file)) {
        neg_data <- tryCatch(read.csv(neg_file), error = function(e) NULL)
        neg_count <- if (!is.null(neg_data)) nrow(neg_data) else 0
      } else {
        message("File not found: ", neg_file)
        neg_count <- 0
      }
      
      # Add counts for the current ontology to the condition's data
      condition_data[[paste0(ont, "_pos")]] <- pos_count
      condition_data[[paste0(ont, "_neg")]] <- neg_count
    }
    
    # Append the condition data to the summary list
    summary_data[[length(summary_data) + 1]] <- condition_data
  }
  
  # Convert the summary data to a data frame
  summary_table <- bind_rows(summary_data)
  
  # Save the summary table to a CSV file
  output_file <- file.path(base_dir, "GO_Enrichment_Summary_Table.csv")
  write.csv(summary_table, output_file, row.names = FALSE)
  
  # Print the summary table for a quick view
  print(summary_table)
  
  # Inform the user where the output file is saved
  message("Summary table saved to: ", output_file)
  
  