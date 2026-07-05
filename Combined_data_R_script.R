require("GenomicAlignments")
require("BiocParallel")
require("GenomicFeatures")
require("Rsamtools")
library(BiocParallel)
library(systemPipeR)
library(tibble)
# create Design for analysis
library(dplyr)
library(org.Mm.eg.db)
library("fastqcr") 
#library(rseqR)
library(edgeR)
#library(org.Hs.eg.db)
library(ggplot2)
library(readxl)
library(writexl)
library(tibble)
library(dplyr)
library(fgsea)
library(msigdbr)
library(Glimma)
library(RColorBrewer)
#library(pvca)

setwd("C:/Users/chuab/Desktop/DEG_Lab_Rotation/Combined_data/Combined_Aligned_Samples")

dir <- "C:/Users/chuab/Desktop/DEG_Lab_Rotation/Combined_data/Combined_Aligned_Samples"

gtf_file <- "C:/Users/chuab/Desktop/DEG_Lab_Rotation/Lab_Rotation_scripts/gencode.vM36.annotation/gencode.vM36.annotation.gtf"
txdb <- txdbmaker::makeTxDbFromGFF(gtf_file, format="gtf")

#load(paste0(dir,"/annot_tab.rdata"))

ebg <- exonsBy(txdb, by="gene")
print(ebg)

#targets           <- read.table("C:/Users/chuab/Desktop/Lab_Rotation_scripts/Gene_Expression_annotation_R_script/Combined_data_target.txt", header=T, sep="\t", stringsAsFactors = F)
targets <- read.delim("C:/Users/chuab/Desktop/DEG_Lab_Rotation/Lab_Rotation_scripts/Gene_Expression_annotation_R_script/Combined_data_target.txt")
targets$batch <- as.factor(targets$batch)
targets$SampleName <- sub("#.*", "", targets$SampleName)
targets$Factor <- sub("#.*", "", targets$Factor)

#targets <- targets[order(targets$SampleName), ]
group             <- targets$Factor
SampleID             <- targets$SampleID
design <- model.matrix(~ 0 + group + batch, data = targets) #design encodes experimental groups into a numeric matrix. This is a Differential Expression Analysis.
colnames(design)  <- gsub("group", "", colnames(design))
print(design)

# Create bam_files by using the FileName column (original BAM file names)
bam_files <- paste(targets$FileName)

# Assign names to bam_files based on the base sample names (without "_good_Aligned.sortedByCoord.out.bam" suffix)
base_sample_names <- sub("^Unknown_", "", sub("_good_Aligned.sortedByCoord.out.bam", "", targets$FileName))
names(bam_files) <- base_sample_names

# Trim any extra whitespace from both bam_files and SampleName columns
bam_files <- trimws(bam_files)
targets$SampleName <- trimws(targets$SampleName)

# Match the order of bam_files with targets$SampleName
bam_files <- bam_files[match(targets$SampleName, names(bam_files))]
print(names(bam_files))  # Check the BAM file names after matching

if (sum(file.exists(bam_files)) != length(bam_files)) {
  print("BAM Files not found!")
}

bamfiles <- BamFileList(bam_files, yieldSize=2000000)

#register(MulticoreParam(8))
register(SerialParam())
register(SnowParam(4))
se <- summarizeOverlaps(features      = ebg
                        , reads         = bamfiles
                        , mode          = "Union"
                        , singleEnd     = TRUE
                        , ignore.strand = TRUE
                        , fragments     = FALSE 
)

countTab              <- assay(se)
woVersion             <- sapply( rownames(countTab), function(x) unlist(strsplit(x, "[.]"))[1] )
rownames(countTab)    <- as.character(woVersion)
# save annotated gene count table #######
#countDFeByg_annot     <- merge(annot.tab, countTab, by.x='ENSEMBL', by.y=0)

countDFeByg <- countTab
file_path <- "C:/Users/chuab/Desktop/DEG_Lab_Rotation/Combined_data/Combined_Aligned_Samples/countDFeByg_annot.xlsx"
# Read the Excel file
countDFeByg <- read_excel(file_path)

# design            <- model.matrix(~ 0 +group) #cellline + time + gender
# colnames(design)  <- gsub("group|batch", "", colnames(design)) #"group|Cellline|time" #Remove the batch if there is an error.

#cont.matrix_2 specifies pairwise comparisons or contrasts for Differential Expression Analysis
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
  HOM_SCM_vs_WT_SCM_CB = SCM_CB_HOM - SCM_CB_WT, #I should have 10 lines, also use the end of the arrow as the main file to minus
  WT_SFM_Cx_vs_WT_SFM_CB = SFM_Cx_WT - SFM_CB_WT, #Comparing wildtypes SFM Cx vs CB
  WT_SCM_Cx_vs_WT_SCM_CB = SFM_Cx_WT - SCM_CB_WT, #Compariing wildtypes SCM Cx sv CB
  
  levels=design
)

#cont.matrix_2
# Extract Ensembl IDs from the row names
rownames(countDFeByg) <- countDFeByg$ENSEMBL
ensembl_ids <- rownames(countDFeByg)
library(org.Mm.eg.db)
gene.ids <- mapIds(org.Mm.eg.db, keys = ensembl_ids, 
                   keytype = "ENSEMBL", column = "SYMBOL")

gene_list <- data.frame(ENSEMBL=rownames(countDFeByg), SYMBOL=gene.ids)
gene_list$ENSEMBL <- rownames(gene_list)

countDFeByg_df <- as.data.frame(countDFeByg)

countDFeByg_df$ENSEMBL <- rownames(countDFeByg)

countDFeByg_annot <- merge(countDFeByg_df,gene_list, by.x='ENSEMBL', by.y=0)

countMatrix <- countDFeByg[, sapply(countDFeByg, is.numeric)] # only uses numerics


# countDFeByg$symbol <- gene_list$SYMBOL

 writexl::write_xlsx(as.data.frame(countDFeByg_annot),"countDFeByg_annot.xlsx")
# countMatrix <-  read_xlsx("countDFeByg_annot.xlsx"), we use this line if we do not want to always run the BAM files over again. However, there may be issues with the other lines below.
 # Therefore, we have the lines below to remove problematic columns and rows as we only want the count information in the count matrix.
 # when we read the excel file, we assign the ensemle ID to the rownames: rownames(countMatrix) <- countMatrix$ENSEMBLE, and then zou remove the ensemble and symbol columns, so the matrix 
 #only contains the count values, and the rownames would be the gene ids
 

# Remove the first column
#rownames(countMatrix) <- countMatrix[, 1]  # Set the first column as row names
#countMatrix <- countMatrix[, -1]          # Remove the first column

#countMatrix <- removeBatchEffect(countMatrix, batch = batch, 
#                                      batch2 = gender)
# Modify column names by removing everything after "_S"
colnames(countMatrix) <- sub("_S.*", "", colnames(countMatrix))
# Verify the change
colnames(countMatrix)

# prepare container with counts and annotations
x                 <- DGEList( counts = countMatrix
                              , group=c(targets$Factor),
                              genes = gene_list)

#rownames(countMatrix)
anyDuplicated(rownames(countMatrix))==0
#plotPCA(x, "Sac")
# conduct normalization. The normalization factors will be stored in the object with an unaltered copy of the counts matrix:

#calc.normfact.out <- calcNormFactors(x, method = "TMM")

#Filtering the data
# filter from edgeR to remove unexpressed genes
keep.exprs        <- filterByExpr(x, group=targets$Factor)
sum(keep.exprs)
x.filtered        <- x[keep.exprs, keep.lib.sizes=FALSE] #This removes lowly expressed genes to improve statistical power.
x.filtered        <- calcNormFactors(x.filtered) #Normalisation : calcNormFactors adjusts for library size differences between samples using TMM (Trimmed Mean of M-values).

duplicated_rows <- duplicated(x.filtered)

if (any(duplicated_rows)) {
  countMatrix_duplicated <- x.filtered[duplicated_rows,]
}



v                 <- voomWithQualityWeights(x.filtered, design, plot=T)
png("voom_plot.png", width = 1200, height = 900, res = 150)
dev.off()

group <- factor(v$targets$group)

jpeg(file= "Myorg_bulk_MDS_plot_Factor.jpeg", width = 4000, height = 3500, res = 300)

plotMDS(v, labels = as.character(group), col = as.numeric(group), cex = 1.5, cex.axis = 1.2)

dev.off()



# New MDS Plot

jpeg(file= "Myorg_bulk_MDS_plot_SampleID.jpeg", width = 4000, height = 3500, res = 300)

plotMDS(v, labels = as.character(SampleID), col = as.numeric(group), cex = 1.5, cex.axis = 1.2)

dev.off()
#duplicateCorrelation(v, design)

fit <- lmFit(v)
fit2 <- contrasts.fit(fit, cont.matrix_2)
fit2 <- eBayes(fit2)
results <- decideTests(fit2, p.value=0.1,method = "global") #These steps fit a linear model, apply contrasts, and determine differentially expressed genes (DEGs).
sum.res <- summary(results)

all_com_ls <- colnames(cont.matrix_2)
name_list <- list()

# Ensure the output directory exists
output_dir <- "C:/Users/chuab/Desktop/DEG_Lab_Rotation/Combined_data/Sequenced_data"
dir.create(output_dir, showWarnings=FALSE)
print(paste("Output directory exists:", file.exists(output_dir)))

# Loop through each contrast and save results
all_com_ls <- colnames(cont.matrix_2)

for (i in seq_along(all_com_ls)) {
  # Debugging: print the value of i
  print(paste("Processing contrast index:", i))  # Check the loop index
  
  # Check the structure of sum.res
  print("Structure of sum.res:")
  print(sum.res)  # Make sure sum.res is in the expected format
  # Save all DEGs
  # Corrected file path with proper syntax
  file_path <- file.path("C:/Users/chuab/Desktop/DEG_Lab_Rotation/Combined_data/Sequenced_data", paste0(all_com_ls[i], '.xlsx'))
  deg_table <- topTable(fit2, coef=i, number=nrow(fit2), adjust.method="BH", p.value=1)
  write_xlsx(deg_table, file_path)
  print(paste("Written:", file_path))
  
  # Save significant DEGs
  num_sig <- sum.res[1, i] + sum.res[3, i]
  file_path_sig <- file.path("C:/Users/chuab/Desktop/DEG_Lab_Rotation/Combined_data/Sequenced_data", paste0('Sig_', all_com_ls[i], '.xlsx'))
  sig_table <- topTable(fit2, coef=i, number=num_sig, adjust.method="BH", p.value=0.05)
  write_xlsx(sig_table, file_path_sig)
  print(paste("Written:", file_path_sig))
}

# Check saved files
print(list.files(output_dir))

 #Results are saved for each contrast into an Excel file.

# Write the list to a text file
name_list <- as.character(name_list)
writeLines(name_list, "name_list.txt")
print("File 'name_list.txt' has been written successfully.")
# The writeLines() function writes each element of the input list (or vector) as a new line in the specified file.
# The output file where the contents of name_list are written. Each element in name_list will appear on a new line in this text file.
# The file name_list.txt will look something like this:T20_CCD1_vs_WT_1.xlsx, Sig_T20_CCD1_vs_WT_1.xlsx, T20_KD_vs_WT_1.xlsx, Sig_T20_KD_vs_WT_1.xlsx)
