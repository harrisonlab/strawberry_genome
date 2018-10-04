#!/bin/bash

# Alignment of minion reads to a minion assembly prior to running nanopolish variants

#$ -S /bin/bash
#$ -cwd
#$ -pe smp 24
#$ -l virtual_free=15.5G
#$ -l h=blacklace11.blacklace

Usage="sub_racon.sh <assembly.fa> <corrected_reads.fq.gz> <number_of_iterations> <output_directory>"
echo "$Usage"

# ---------------
# Step 1
# Collect inputs
# ---------------

AssemblyIn=$1
# Fastq1=$(ls /data/scratch/armita/strawberry_assembly/qc_dna/minion/F.ananassa/redgauntlet/redgauntlet_2017_reads_trim.fastq.gz)
# Fastq2=$(ls /data/scratch/armita/strawberry_assembly/qc_dna/minion/F.ananassa/redgauntlet/redgauntlet_2018_reads_trim.fastq.gz)
# Fastq3=$(ls /data/scratch/armita/strawberry_assembly/qc_dna/minion/F.ananassa/redgauntlet/FAH88888_trim.fastq.gz)
# Fastq4=$(ls /data/scratch/armita/strawberry_assembly/qc_dna/minion/F.ananassa/redgauntlet/PAC21038_trim.fastq.gz)
# Fastq5=$(ls /data/scratch/armita/strawberry_assembly/qc_dna/minion/F.ananassa/redgauntlet/PAC21093_trim.fastq.gz)
Iterations=$2
OutDir=$3

echo "Assembly - $AssemblyIn"
echo "Fasta reads - $ReadsIn1"
echo "Fasta reads - $ReadsIn2"
echo "OutDir - $OutDir"

CurDir=$PWD
WorkDir=$TMPDIR/racon
mkdir -p $WorkDir
cd $WorkDir

Assembly=$(basename $AssemblyIn)
Assembly=$(echo $Assembly | sed 's/.utg/.fa/g')
# Reads=appended_reads.fastq.gz
Reads=$(ls /data2/scratch2/armita/strawberry_genome/appended_reads.fq.gz)
cp $CurDir/$AssemblyIn $Assembly
# cat $Fastq1 $Fastq2 $Fastq3 $Fastq4 $Fastq5 > $Reads

Prefix=$(echo $Assembly | cut -f1 -d '.')

mkdir -p $CurDir/$OutDir

cp $Assembly current-assembly.fa
for i in $(seq 1 $Iterations); do
  echo "Iteration - $i"
  minimap2 \
    -x map-ont \
    -t 24 \
    current-assembly.fa \
    $Reads \
    > racon_round_$i.reads_mapped.paf
  racon --threads 24 $Reads racon_round_$i.reads_mapped.paf current-assembly.fa racon_round_$i.fasta
  cp racon_round_$i.fasta current-assembly.fa
  cp racon_round_$i.fasta $CurDir/$OutDir/"$Prefix"_racon_round_$i.fasta
done
