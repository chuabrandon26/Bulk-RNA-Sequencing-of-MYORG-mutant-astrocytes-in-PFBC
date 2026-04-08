# Bulk_RNAseq_PFBC_project for MYORG Dysfunction

Overview:
This project implements a bulk transcriptomic pipeline to study astrocytic gene regulation and its contribution to the pathogenesis of Primary Familial Brain Calcification (PFBC). The focus is on the impact of biallelic loss-of-function mutations in the MYORG gene, which encodes an ER-localized glycosidase, and how its dysfunction drives inflammatory signaling, apoptosis, and metabolic dysregulation in astrocytes under different culture conditions.

The analysis framework incorporates differential expression modeling, pathway-level enrichment, and functional ontology analysis to ensure deep biological interpretability of the transcriptomic shifts.

# Data
1) Bulk RNA sequencing data obtained from primary mouse astrocytes (cortex and cerebellum)
2) Genotypes: Wild-type (WT) and MYORG-knockout (HOM) mice
3) Culture Conditions: Grown in either serum-containing (SCM) or serum-free (SFM) medium
4) Reference Genome: Mus musculus (mm10/GRCm38) with GENCODE M36 annotations

## Pipeline Architecture

### Core Transcriptomic Workflows

#### Preprocessing & Alignment
- Adapter trimming and quality control via **Trim Galore** and FastQC
- Spliced read alignment to the reference genome using **STAR aligner**
- Read quantification into gene-by-sample count matrices using **GenomicAlignments** (summarizeOverlaps)

#### Differential Expression (limma-voom)
- Library sizes normalized via Trimmed Mean of M-values (TMM) using `edgeR`
- `voomWithQualityWeights` applied to estimate mean-variance relationships and assign precision weights
- Linear modeling and empirical Bayes moderation (`eBayes`) used for robust variance estimation

---

## Analysis Strategy

- Separate pairwise contrasts (10 total) are analyzed to isolate:
  - **Genotype effects** (e.g., WT vs HOM)
  - **Environmental/Serum effects** (e.g., SCM vs SFM)
  - **Regional effects** (e.g., Cortex vs Cerebellum)
- Multidimensional scaling (MDS) is used to validate sample clustering by genotype, region, and medium prior to modeling.

---

## Downstream Enrichment Approaches

Three complementary approaches were explored to interpret the biological meaning of the DEGs:

### 1. Differential Expression Analysis (DEA)
- Statistically models raw count data
- Computes log-fold changes and adjusted p-values
- Identifies single genes with high-confidence condition-specific expression shifts

### 2. Gene Set Enrichment Analysis (GSEA)
- Utilizes the `fgsea` algorithm with MSigDB mouse hallmark gene sets
- Ranks all expressed genes by a combined metric: $sign(log_{2}FC) \times -\log_{10}(p\text{-value})$
- Identifies broad, coordinated pathway-level shifts without arbitrary p-value cutoffs

### 3. Gene Ontology (GO) Enrichment
- Utilizes `clusterProfiler` for over-representation analysis
- Maps gene symbols to Entrez IDs via `biomaRt`
- Evaluates significant DEGs across Biological Process (BP), Cellular Component (CC), and Molecular Function (MF)

---

## Experiments & Key Findings

- Models trained and evaluated across 10 defined pairwise contrasts.
- Comparisons performed between:
  - Control (WT) vs Mutated (HOM) regulatory programs
  - Baseline (SCM) vs Stress/Quiescent (SFM) environments
- Analysis identified condition-dependent regulatory rewiring:
  - **Apoptosis & Oxidative Phosphorylation:** Strongly downregulated in HOM SFM cortex, but upregulated in HOM SFM cerebellum.
  - **TNFα/NF-кВ Signaling:** Consistently activated in SFM conditions, linking MYORG dysfunction to maladaptive inflammatory states.

---
## The Script

This is the core project logic used in this repository. It covers: loading BAM files to generate count matrices, filtering and normalizing via TMM, performing limma-voom linear modeling, executing GSEA for pathway analysis, and extracting GO enrichment profiles.

```R
# ----------------------------
# 0) Imports + Setup
# ----------------------------
require("GenomicAlignments")
require("BiocParallel")
require("GenomicFeatures")
require("Rsamtools")
library(dplyr)
library(org.Mm.eg.db)
library(edgeR)
library(ggplot2)
library(readxl)
library(writexl)
library(fgsea)
library(msigdbr)
library(Glimma)
library(biomaRt)
library(clusterProfiler)
library(enrichplot)

setwd("C:/Users/chuab/Desktop/DEG_Lab_Rotation/Combined_data/Combined_Aligned_Samples")
device_cores <- 4 # Adjust based on parallelization needs

# ----------------------------
# 1) Load Genome Annotations & Targets
# ----------------------------
gtf_file <- "C:/Users/chuab/Desktop/DEG_Lab_Rotation/Lab_Rotation_scripts/gencode.vM36.annotation/gencode.vM36.annotation.gtf"
txdb <- txdbmaker::makeTxDbFromGFF(gtf_file, format="gtf")
ebg <- exonsBy(txdb, by="gene")

targets <- read.delim("C:/Users/chuab/Desktop/DEG_Lab_Rotation/Lab_Rotation_scripts/Gene_Expression_annotation_R_script/Combined_data_target.txt")
targets$batch <- as.factor(targets$batch)
targets$SampleName <- trimws(sub("#.*", "", targets$SampleName))
targets$Factor <- sub("#.*", "", targets$Factor)

group <- targets$Factor
SampleID <- targets$SampleID
design <- model.matrix(~ 0 + group + batch, data = targets)
colnames(design) <- gsub("group", "", colnames(design))

# ----------------------------
# 2) Read BAMs & Summarize Overlaps
# ----------------------------
bam_files <- paste(targets$FileName)
base_sample_names <- sub("^Unknown_", "", sub("_good_Aligned.sortedByCoord.out.bam", "", targets$FileName))
names(bam_files) <- base_sample_names
bam_files <- trimws(bam_files)
bam_files <- bam_files[match(targets$SampleName, names(bam_files))]

bamfiles <- BamFileList(bam_files, yieldSize=2000000)
register(SnowParam(device_cores))

se <- summarizeOverlaps(features = ebg, 
                        reads = bamfiles, 
                        mode = "Union", 
                        singleEnd = TRUE, 
                        ignore.strand = TRUE, 
                        fragments = FALSE)

countTab <- assay(se)
woVersion <- sapply(rownames(countTab), function(x) unlist(strsplit(x, "[.]"))[1])
rownames(countTab) <- as.character(woVersion)

# ----------------------------
# 3) Filter, Normalize (TMM), and Map Gene IDs
# ----------------------------
ensembl_ids <- rownames(countTab)
gene.ids <- mapIds(org.Mm.eg.db, keys = ensembl_ids, keytype = "ENSEMBL", column = "SYMBOL")
gene_list <- data.frame(ENSEMBL=rownames(countTab), SYMBOL=gene.ids)

countMatrix <- countTab[, sapply(as.data.frame(countTab), is.numeric)]
colnames(countMatrix) <- sub("_S.*", "", colnames(countMatrix))

x <- DGEList(counts = countMatrix, group = c(targets$Factor), genes = gene_list)
keep.exprs <- filterByExpr(x, group=targets$Factor)
x.filtered <- x[keep.exprs, keep.lib.sizes=FALSE]
x.filtered <- calcNormFactors(x.filtered)

# ----------------------------
# 4) limma-voom Differential Expression
# ----------------------------
v <- voomWithQualityWeights(x.filtered, design, plot=T)

# Save MDS Plot
jpeg(file= "Myorg_bulk_MDS_plot_Factor.jpeg", width = 4000, height = 3500, res = 300)
plotMDS(v, labels = as.character(group), col = as.numeric(as.factor(group)), cex = 1.5)
dev.off()

cont.matrix_2 <- makeContrasts(
  WT_SFM_vs_WT_SCM_Cx = SFM_Cx_WT - SCM_Cx_WT,
  HOM_SFM_vs_WT_SFM_Cx = SFM_Cx_HOM - SFM_Cx_WT,
  HOM_SFM_vs_HOM_SCM_Cx = SFM_Cx_HOM - SCM_Cx_HOM,
  HOM_SCM_vs_WT_SFM_Cx = SCM_Cx_HOM - SFM_Cx_WT,
  HOM_SCM_vs_WT_SCM_Cx = SCM_Cx_HOM - SCM_Cx_WT,
  WT_SFM_vs_WT_SCM_CB = SFM_CB_WT - SCM_CB_WT,
  HOM_SFM_vs_WT_SFM_CB = SFM_CB_HOM - SCM_CB_HOM,
  HOM_SFM_vs_HOM_SCM_CB = SFM_CB_HOM - SCM_CB_HOM,
  HOM_SCM_vs_WT_SFM_CB = SCM_CB_HOM - SFM_CB_WT,
  HOM_SCM_vs_WT_SCM_CB = SCM_CB_HOM - SCM_CB_WT,
  WT_SFM_Cx_vs_WT_SFM_CB = SFM_Cx_WT - SFM_CB_WT,
  WT_SCM_Cx_vs_WT_SCM_CB = SFM_Cx_WT - SCM_CB_WT,
  levels=design
)

fit <- lmFit(v)
fit2 <- contrasts.fit(fit, cont.matrix_2)
fit2 <- eBayes(fit2)
results <- decideTests(fit2, p.value=0.05, method = "global")
sum.res <- summary(results)

output_dir <- "C:/Users/chuab/Desktop/DEG_Lab_Rotation/Combined_data/Sequenced_data"
dir.create(output_dir, showWarnings=FALSE)

all_com_ls <- colnames(cont.matrix_2)
for (i in seq_along(all_com_ls)) {
  # Save all DEGs
  file_path <- file.path(output_dir, paste0(all_com_ls[i], '.xlsx'))
  deg_table <- topTable(fit2, coef=i, number=nrow(fit2), adjust.method="BH", p.value=1)
  write_xlsx(deg_table, file_path)
  
  # Save significant DEGs (p < 0.05)
  num_sig <- sum.res[1, i] + sum.res[3, i]
  file_path_sig <- file.path(output_dir, paste0('Sig_', all_com_ls[i], '.xlsx'))
  sig_table <- topTable(fit2, coef=i, number=num_sig, adjust.method="BH", p.value=0.05)
  write_xlsx(sig_table, file_path_sig)
}

# ----------------------------
# 5) Gene Set Enrichment Analysis (GSEA)
# ----------------------------
gmt.file <- "C:/Users/chuab/Desktop/DEG_Lab_Rotation/Lab_Rotation_scripts/GSEA_R_script/mh.all.v2024.1.Mm.symbols.gmt"
pathways <- gmtPathways(gmt.file)

for (current_file in paste0(all_com_ls, ".xlsx")) {
  current_marker_expr_df <- readxl::read_xlsx(file.path(output_dir, current_file)) %>%
    group_by(SYMBOL) %>%
    filter(AveExpr == max(AveExpr, na.rm = TRUE)) %>%
    ungroup() %>% filter(!is.na(SYMBOL))
  
  # Calculate ranking metric: sign(logFC) * -log10(p-value)
  current_marker_expr_df$comb_val <- sign(current_marker_expr_df$logFC) * -log10(current_marker_expr_df$P.Value)
  ranks <- current_marker_expr_df$comb_val
  names(ranks) <- current_marker_expr_df$SYMBOL
  ranks <- ranks[!(is.infinite(ranks) | is.na(ranks))]
  
  set.seed(42)
  fgseaRes <- fgsea::fgsea(pathways, ranks, minSize = 10, maxSize = Inf, scoreType = "std", nproc = 1)
  gsea_sig <- fgseaRes[fgseaRes$padj < 0.05,]
  
  # Save and plot
  current_file_filtered <- gsub(".xlsx", "", current_file)
  gsea_sig_df <- gsea_sig[, c("pathway", "NES", "pval", "padj", "size")]
  write.csv(gsea_sig_df, paste0("GSEA_results_", current_file_filtered, ".csv"), row.names = FALSE)
  
  gsea_plot <- ggplot(gsea_sig, aes(x = NES, y = pathway, color = pval, size = size)) + 
    geom_point(stat = 'identity') + theme_bw() + ggtitle(paste0("GSEA on ", current_file_filtered))
  ggsave(paste0("GSEA_hallmark_", current_file_filtered, ".png"), plot = gsea_plot, width = 26, height = 10)
}

# ----------------------------
# 6) Gene Ontology (GO) Enrichment (clusterProfiler)
# ----------------------------
ensembl <- useMart("ensembl", dataset = "mmusculus_gene_ensembl")

find_go_terms <- function(gene_list){
  gene_ids <- getBM(attributes = c('mgi_symbol', 'entrezgene_id'), filters = 'mgi_symbol', values = gene_list, mart = ensembl)
  go_enrichment <- enrichGO(gene = unique(gene_ids$entrezgene_id), OrgDb = org.Mm.eg.db, ont = "ALL", 
                            pAdjustMethod = "bonferroni", pvalueCutoff = 0.05, qvalueCutoff = 0.05, readable = TRUE)
  return(list(go_enrichment = go_enrichment, gene_ids = gene_ids))
}

# Example wrapper for one contrast
current_marker_expr_df <- readxl::read_xlsx(file.path(output_dir, "Sig_WT_SFM_Cx_vs_WT_SFM_CB.xlsx"))
negative_genes <- current_marker_expr_df[current_marker_expr_df$logFC < 0,]
positive_genes <- current_marker_expr_df[current_marker_expr_df$logFC > 0,]

for (ont_type in c('BP', 'CC', 'MF')) {
  if (nrow(positive_genes) > 0) {
    results_pos <- find_go_terms(positive_genes$SYMBOL)
    sag_pos <- data.frame(results_pos$go_enrichment)
    res_df_pos <- sag_pos[sag_pos$p.adjust < 0.05 & sag_pos$ONTOLOGY == ont_type, ]
    write.csv(res_df_pos, paste0('Clusterprofiler_GO_', ont_type, '_pos.csv'), row.names = FALSE)
  }
  if (nrow(negative_genes) > 0) {
    results_neg <- find_go_terms(negative_genes$SYMBOL)
    sag_neg <- data.frame(results_neg$go_enrichment)
    res_df_neg <- sag_neg[sag_neg$p.adjust < 0.05 & sag_neg$ONTOLOGY == ont_type, ]
    write.csv(res_df_neg, paste0('Clusterprofiler_GO_', ont_type, '_neg.csv'), row.names = FALSE)
  }
}
