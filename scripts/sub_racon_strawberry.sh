#!/bin/bash

# Alignment of minion reads to a minion assembly prior to running nanopolish variants

#$ -S /bin/bash
#$ -cwd
#$ -pe smp 16
#$ -l virtual_free=15.5G
#$ -l h=blacklace11.blacklace

Usage="sub_racon.sh <assembly.fa> <corrected_reads.fq.gz> <number_of_iterations> <output_directory>"
echo "$Usage"

# ---------------
# Step 1
# Collect inputs
# ---------------

AssemblyIn=$1
Iterations=$2
OutDir=$3

echo "Assembly - $AssemblyIn"
echo "Fasta reads - $ReadsIn1"
echo "Fasta reads - $ReadsIn2"
echo "OutDir - $OutDir"

CurDir=$PWD
# WorkDir=$TMPDIR/racon
WorkDir=/data2/scratch2/armita/strawberry_genome/racon
mkdir -p $WorkDir
cd $WorkDir

Assembly=$(basename $AssemblyIn)
Assembly=$(echo $Assembly | sed 's/.utg/.fa/g')
# Reads=appended_reads.fastq.gz
# Reads=$(ls /data2/scratch2/armita/strawberry_genome/appended_reads.fq.gz)
Reads=$(ls /data2/scratch2/armita/strawberry_genome/appended_reads_22-01-19.fq.gz)
cp $CurDir/$AssemblyIn $Assembly

Prefix=$(echo $Assembly | cut -f1 -d '.')

mkdir -p $CurDir/$OutDir

cp $Assembly current-assembly.fa
for i in $(seq 1 $Iterations); do
  echo "Iteration - $i"
  minimap2 \
    -x map-ont \
    -t 16 \
    current-assembly.fa \
    $Reads \
    > racon_round_$i.reads_mapped.paf
  racon --threads 16 $Reads racon_round_$i.reads_mapped.paf current-assembly.fa racon_round_$i.fasta
  cp racon_round_$i.fasta current-assembly.fa
  cp racon_round_$i.fasta $CurDir/$OutDir/"$Prefix"_racon_round_$i.fasta
done
