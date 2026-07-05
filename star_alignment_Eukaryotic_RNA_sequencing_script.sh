#!/bin/bash
#SBATCH --mem=100G
#SBATCH --output=star_alignment_%j.out
#SBATCH --error=star_alignment_%j.err

# Define the directory for the genome index
genomeDir="/net/bq-storage/ag-kummer/Babak/genome_alignment/star_index"

# Define the common parameters
commonParams="--genomeDir $genomeDir --readFilesCommand gunzip -c --outSAMtype BAM SortedByCoordinate --runThreadN 8 --limitBAMsortRAM 10000000000"

# Array of input files
inputFiles=(
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0001_good_1_val_1.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0001_good_2_val_2.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0002_good_1_val_1.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0002_good_2_val_2.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0003_good_1_val_1.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0003_good_2_val_2.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0004_good_1_val_1.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0004_good_2_val_2.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0005_good_1_val_1.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0005_good_2_val_2.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0006_good_1_val_1.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0006_good_2_val_2.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0007_good_1_val_1.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0007_good_2_val_2.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0008_good_1_val_1.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0008_good_2_val_2.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0009_good_1_val_1.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0009_good_2_val_2.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0010_good_1_val_1.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0010_good_2_val_2.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0011_good_1_val_1.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0011_good_2_val_2.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0012_good_1_val_1.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0012_good_2_val_2.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0013_good_1_val_1.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0013_good_2_val_2.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0014_good_1_val_1.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0014_good_2_val_2.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0015_good_1_val_1.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0015_good_2_val_2.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0016_good_1_val_1.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0016_good_2_val_2.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0017_good_1_val_1.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0017_good_2_val_2.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0018_good_1_val_1.fq.gz"
"/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/trimmed_Eukaryotic_mRNA_sequencing/Unknown_CN274-001U0018_good_2_val_2.fq.gz"
)

# Loop over input files and run STAR for paired-end alignment
for ((i=0; i<${#inputFiles[@]}; i+=2)); do
    forwardRead="${inputFiles[i]}"
    reverseRead="${inputFiles[i+1]}"
    sampleName=$(basename "$forwardRead" | sed 's/_1_val_1.fq.gz//')
    outputPrefix="/net/bq-storage/ag-kummer/Babak/genome_alignment/Eukaryotic_Strand_Specific_mRNA_Sequencing_with_reference_genome/Aligned_Eukaryotic_mRNA_sequencing/${sampleName}_"

    # Run STAR
    /net/bq-storage/ag-kummer/Babak/genome_alignment/STAR-2.7.3a/bin/Linux_x86_64/STAR \
        --readFilesIn "$forwardRead" "$reverseRead" \
        $commonParams \
        --outFileNamePrefix "$outputPrefix"
done
