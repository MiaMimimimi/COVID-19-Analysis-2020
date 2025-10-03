#!/bin/bash

# ==============================================================
# Extract Spike protein sequences directly for selected samples
# ==============================================================

mkdir -p blastdb blast_output
>spike_protein_all.fa

# Loop through all samples in sample_info2.txt (skip header)
tail -n +2 ../sample_info2.txt | while read -r sample _; do
    genome="../single_genome/${sample}.fa"
    db="./blastdb/${sample}"

    # 1. Make BLAST database
    makeblastdb -in "$genome" -dbtype nucl -parse_seqids -out "$db"

    # 2. Run BLAST for Spike reference
    blast_out="./blast_output/${sample}_out"
    blastn -db "$db" -query ./spike_protein_ref.fa -outfmt 7 -out "$blast_out"

    # 3. Parse top hit (ignore comments)
    hit=$(grep -v "^#" "$blast_out" | head -1)

    if [ -n "$hit" ]; then
        # Parse fields: qid sid %id alen mm go qs qe ss se evalue bitscore
        read -r qid sid pid alen mm go qs qe ss se evalue bitscore <<< "$hit"

        # 4. Extract sequence with samtools faidx
        samtools faidx "$genome" "${sid}:${ss}-${se}" >> spike_protein_all.fa
    else
        echo "No hit found for $sample" >&2
    fi
done
# --------------------------------------------------------------
# Clean FASTA names (remove coordinate)
# --------------------------------------------------------------
sed 's/:.*//g' spike_protein_all.fa > spike_protein_all_shortname.fa

# --------------------------------------------------------------
# Align spike protein sequences (MAFFT)
# --------------------------------------------------------------
mafft --thread 8 --threadtb 5 --threadit 0 --inputorder --anysymbol --clustalout --auto spike_protein_all_shortname.fa > cov19_aln.clustal

# --------------------------------------------------------------
# Infer Maximum Likelihood (ML) tree with IQ-TREE
# --------------------------------------------------------------
mkdir -p iqtree_output
iqtree2 -s ./cov19_aln.clustal -m TEST -B 2000 -alrt 1000 -nt AUTO -pre ./iqtree_output/cov19_tree

# --------------------------------------------------------------
# Step 9: Visualize tree in R
# Script: tree.Rmd
# --------------------------------------------------------------
