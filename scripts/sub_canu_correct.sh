#!/bin/bash

# Assemble PacBio data using Canu

#$ -S /bin/bash
#$ -cwd
#$ -pe smp 23
#$ -l virtual_free=15.5G
#$ -l h=blacklace11.blacklace


Usage="sub_canu_correction.sh <reads.fq> <Genome_size[e.g.45m]> <outfile_prefix> <output_directory> [<specification_file.txt>]"
echo "$Usage"

# ---------------
# Step 1
# Collect inputs
# ---------------

# FastqIn=$1
# Size=$2
# Prefix=$3
# OutDir=$4
# AdditionalCommands=""
# if [ $5 ]; then
#   SpecFile=$5
#   AdditionalCommands="-s $SpecFile"
# fi
# echo  "Running Canu with the following inputs:"
# echo "FastqIn - $FastqIn"
# echo "Size - $Size"
# echo "Prefix - $Prefix"
# echo "OutDir - $OutDir"



# Fastq1=$(ls /data/scratch/armita/strawberry_assembly/qc_dna/minion/F.ananassa/redgauntlet/redgauntlet_2017_reads_trim.fastq.gz)
# Fastq2=$(ls /data/scratch/armita/strawberry_assembly/qc_dna/minion/F.ananassa/redgauntlet/redgauntlet_2018_reads_trim.fastq.gz)
# Fastq3=$(ls /data/scratch/armita/strawberry_assembly/qc_dna/minion/F.ananassa/redgauntlet/FAH88888_trim.fastq.gz)
# Fastq4=$(ls /data/scratch/armita/strawberry_assembly/qc_dna/minion/F.ananassa/redgauntlet/PAC21038_trim.fastq.gz)
# Fastq5=$(ls /data/scratch/armita/strawberry_assembly/qc_dna/minion/F.ananassa/redgauntlet/PAC21093_trim.fastq.gz)
# Fastq6=$(ls /data/scratch/armita/strawberry_assembly/qc_dna/minion/F.ananassa/redgauntlet/PAD05283_trim.fastq.gz)
# Fastq7=$(ls /data/scratch/armita/strawberry_assembly/qc_dna/minion/F.ananassa/redgauntlet/PAD05283b_trim.fastq.gz)
# Fastq8=$(ls /data/scratch/armita/strawberry_assembly/qc_dna/minion/F.ananassa/redgauntlet/PAD06089_trim.fastq.gz)

# Size=720m
Size=1440m
Prefix=Fa_Rg_appended
OutDir=assembly/canu-1.8/F.ananassa/redgauntlet_haplotyped
echo "Running Canu with the following inputs:"
echo "FastqIn - $Fastq1 $Fastq2 $Fastq3 $Fastq4 $Fastq5"
echo "Size - $Size"
echo "Prefix - $Prefix"
echo "OutDir - $OutDir"

CurPath=$PWD
# WorkDir="$TMPDIR"/canu
WorkDir=/data2/scratch2/armita/strawberry_genome/canu

# ---------------
# Step 2
# Run Canu
# ---------------
echo "Concatenating reads"
mkdir -p $WorkDir
cd $WorkDir
mkdir -p /data2/scratch2/armita/strawberry_genome
# Fastq=/data2/scratch2/armita/strawberry_genome/appended_reads.fq.gz
Fastq=/data2/scratch2/armita/strawberry_genome/appended_reads_22-01-19.fq.gz
# cat $Fastq1 $Fastq2 $Fastq3 $Fastq4 $Fastq5 > $Fastq

echo "Reads concatenated"

canu \
  -correct \
  -useGrid=false \
  -overlapper=mhap \
  -utgReAlign=true \
  -d $WorkDir/assembly \
  -p $Prefix \
  genomeSize="$Size" \
  -nanopore-raw $Fastq \
  2>&1 | tee canu_run_log.txt

canu \
  -trim \
  -useGrid=false \
  -overlapper=mhap \
  -utgReAlign=true \
  -d $WorkDir/assembly \
  -p $Prefix \
  genomeSize="$Size" \
  -nanopore-corrected assembly/$Prefix.correctedReads.fasta.gz \
  2>&1 | tee canu_run_log.txt


mkdir -p $CurPath/$OutDir
cp canu_run_log.txt $CurPath/$OutDir/.
cp $WorkDir/assembly/* $CurPath/$OutDir/.
