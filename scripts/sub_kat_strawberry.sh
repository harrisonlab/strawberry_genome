#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -pe smp 24
#$ -l virtual_free=15.5G
# #$ -l h=blacklace11.blacklace

# Assess assembly quality by plotting occurence of kmers in a genome assembly
# vs their occurence in illumina data.


Threads=24

# ---------------
# Step 1
# Collect inputs
# ---------------

Assembly=$(basename $1)
OutDir=$2
Prefix=$3
MaxX="500"
CurDir=$PWD
echo "Running KAT with the following inputs:"
echo "Assembly - $Assembly"
echo "OutDir - $OutDir"
echo "Outfile prefix = $Prefix"

# ---------------
# Step 2
# Copy data
# ---------------
WorkDir=$TMPDIR/kat
mkdir -p $WorkDir
cd $WorkDir
cp $CurDir/$1 $Assembly

Reads=$(ls /home/groups/harrisonlab/project_files/fragaria_x_ananassa/octoseq/PE/*.gz)
cat $Reads > reads.fa

# ---------------
# Step 3
# Generate KAT kmer spectrum
# ---------------
#

PYTHONPATH="/home/armita/.local/lib/python3.5/site-packages:/home/armita/prog/kat"

mkdir out
kat comp -o out/${Prefix} -m 21 -t $Threads reads.fa $Assembly
# /home/armita/prog/kat/KAT/scripts/kat/plot/spectra_mx.py --intersect -o kat_out.png kat_out-main.mx
ProgDir=/home/armita/prog/kat/KAT/scripts/kat/plot
$ProgDir/spectra_cn.py -o out/${Prefix}_spectra.png out/${Prefix}-main.mx
if [ $MaxX ]; then
  $ProgDir/spectra_cn.py -o out/${Prefix}_spectra_X-${MaxX}.png -x $MaxX out/${Prefix}-main.mx
fi

# $ProgDir/spectra_mx.py --intersect -o out/${Prefix}_spectra.png kat_out-main.mx


# ---------------
# Step 4
# Kmer coverage per contig
# ---------------

# kat sect -o out/${Prefix}_sect_reads -m 21 -t 8 $Assembly reads.fa
# kat sect -o out/${Prefix}_sect_assembly -m 21 -t 8 $Assembly $Assembly


mkdir -p ${CurDir}/${OutDir}
mv out/* ${CurDir}/${OutDir}/.
