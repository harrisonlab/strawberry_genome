# strawberry_genome
Commands used in the de novo assembly of octoploid strawberry

Commands used in the assembly of minion sequence data

External sequencing data was downloaded to:

```bash
  /data/seq_data/external/redgauntlet_promethion_downloads
```

```bash
OutDataDir=/data/scratch/armita/strawberry_assembly
mkdir -p $OutDataDir
cd $OutDataDir

Zipped2017=$(ls /data/seq_data/minion/2017/*_RG*.tar.gz)
for File in $(ls $Zipped2017 | head -n1); do
  tar -zxvf $File --no-anchor --wildcards '*.fastq'
done

for File in $(ls $Zipped2017 | tail -n+2); do
  tar -zxvf $File --no-anchor --wildcards '*.fastq'
done
```

```bash
ProjectDir=/data/scratch/armita/strawberry_assembly
Organism=F.ananassa
Strain=redgauntlet
OutDir=$ProjectDir/raw_dna/minion/$Organism/$Strain
mkdir -p $OutDir

cat */*/*.fastq | gzip -cf > $OutDir/${Strain}_2017_reads.fastq.gz
cat /data/seq_data/minion/2018/*RG*/*/*/*.fastq /data/seq_data/minion/2018/*_Redgauntlet-1D-sheared/*/*/*.fastq | gzip -cf > $OutDir/${Strain}_2018_reads.fastq.gz
cat /data/seq_data/external/redgauntlet_promethion_downloads/*/postprocessing/*.fastq.gz > $OutDir/${Strain}_keygene.fastq.gz
```

### Removal of adapters

Splitting reads and trimming adapters using porechop

```bash
	for RawReads in $(ls ../../../seq_data/external/redgauntlet_promethion_downloads/*/postprocessing/*.fastq.gz | grep 'PAC21093'); do
    Organism=F.ananassa
    Strain=redgauntlet
    echo "$Organism - $Strain"
  	OutDir=raw_dna/minion/F.ananassa/redgauntlet/split
    mkdir -p $OutDir
    gunzip -c $RawReads | split -l 1000000 - $OutDir/'PAC21093_split_'
    for File in $(ls $OutDir/PAC21093_split_* | grep -v 'fq.gz'); do
      cat $File | gzip -cf > ${File}.fq.gz
    done
  done
```
```bash
	for RawReads in $(ls raw_dna/minion/F.ananassa/redgauntlet/split/*.fq.gz); do
    Organism=F.ananassa
    Strain=redgauntlet
    Jobs=$(qstat | grep 'sub_pore' | grep 'qw' | wc -l)
    while [ $Jobs -gt 1 ]; do
    sleep 1m
    printf "."
    Jobs=$(qstat | grep 'sub_pore' | grep 'qw' | wc -l)
    done		
    printf "\n"
    echo "$Organism - $Strain"
  	OutDir=qc_dna/minion/$Organism/$Strain/split
  	ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/dna_qc
  	qsub $ProgDir/sub_porechop.sh $RawReads $OutDir
  done
```

```bash
cat qc_dna/minion/F.ananassa/redgauntlet/split/* > qc_dna/minion/F.ananassa/redgauntlet/PAC21093_trim.fastq.gz
```

```bash
	for RawReads in $(ls ../../../seq_data/external/redgauntlet_promethion_downloads/*/postprocessing/*.fastq.gz); do
    Organism=F.ananassa
    Strain=redgauntlet
    echo "$Organism - $Strain"
  	OutDir=qc_dna/minion/$Organism/$Strain
  	ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/dna_qc
  	qsub $ProgDir/sub_porechop_high_mem.sh $RawReads $OutDir
  done
```

### Perform assembly

```bash
ProgDir=/home/armita/git_repos/emr_repos/scripts/strawberry_genome/scripts
qsub $ProgDir/sub_canu_correct.sh
```

This job failed due the high number of short reads. Following the instructions the
following commands was used to carry on anyway and the job resubmitted.

```bash
cat /data/scratch/armita/strawberry_assembly/raw_dna/minion/F.ananassa/redgauntlet/split/* > /data/scratch/armita/strawberry_assembly/qc_dna/minion/F.ananassa/redgauntlet/PAC21093_trim.fastq.gz
```

```
-- In gatekeeper store 'correction/Fa_Rg_appended.gkpStore':
--   Found 4865813 reads.
--   Found 61390442243 bases (85.26 times coverage).
--
--   Read length histogram (one '*' equals 41501.04 reads):
--        0   9999 2905073 **********************************************************************
--    10000  19999 879511 *********************
--    20000  29999 508649 ************
--    30000  39999 291504 *******
--    40000  49999 149895 ***
--    50000  59999  71344 *
--    60000  69999  31862
--    70000  79999  13940
--    80000  89999   6404
--    90000  99999   3257
--   100000 109999   1871
--   110000 119999    980
--   120000 129999    600
--   130000 139999    366
--   140000 149999    223
--   150000 159999    139
--   160000 169999     68
--   170000 179999     34
--   180000 189999     25
--   190000 199999     16
--   200000 209999     12
--   210000 219999      6
--   220000 229999      4


--   1210000 1219999      1
```



### Assembly using SMARTdenovo

```bash
for CorrectedReads in $(ls assembly/canu-1.6/*/*/*.trimmedReads.fasta.gz); do
Organism=$(echo $CorrectedReads | rev | cut -f3 -d '/' | rev)
Strain=$(echo $CorrectedReads | rev | cut -f2 -d '/' | rev)
Prefix="$Strain"_smartdenovo
OutDir=assembly/SMARTdenovo/$Organism/"$Strain"
ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/assemblers/SMARTdenovo
qsub $ProgDir/sub_SMARTdenovo.sh $CorrectedReads $Prefix $OutDir
done
```


Quast and busco were run to assess the effects of racon on assembly quality:

```bash
for Assembly in $(ls assembly/SMARTdenovo/*/*/*.dmo.lay.utg); do
  Strain=$(echo $Assembly | rev | cut -f2 -d '/' | rev)
  Organism=$(echo $Assembly | rev | cut -f3 -d '/' | rev)  
	echo "$Organism - $Strain"
  OutDir=$(dirname $Assembly)
	ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/assemblers/assembly_qc/quast
  qsub $ProgDir/sub_quast.sh $Assembly $OutDir
	OutDir=gene_pred/busco/$Organism/$Strain/assembly
	BuscoDB=$(ls -d /home/groups/harrisonlab/dbBusco/embryophyta_odb10)
	ProgDir=/home/armita/git_repos/emr_repos/tools/gene_prediction/busco
	qsub $ProgDir/sub_busco3.sh $Assembly $BuscoDB $OutDir
done
```

Error correction using racon:

```bash
for Assembly in $(ls assembly/SMARTdenovo/*/*/*.dmo.lay.utg); do
Strain=$(echo $Assembly | rev | cut -f2 -d '/' | rev)
Organism=$(echo $Assembly | rev | cut -f3 -d '/' | rev)
echo "$Organism - $Strain"
# ReadsFq=$(ls qc_dna/minion/*/$Strain/*q.gz)
Iterations=10
OutDir=$(dirname $Assembly)"/racon_$Iterations"
ProgDir=/home/armita/git_repos/emr_repos/scripts/strawberry_genome/scripts
qsub $ProgDir/sub_racon_strawberry.sh $Assembly $Iterations $OutDir
done
```


```bash
ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/assemblers/assembly_qc/quast
# for Assembly in $(ls assembly/SMARTdenovo/*/*/racon_10/*.fasta | grep 'round_10'); do
for Assembly in $(ls assembly/SMARTdenovo/*/*/racon_10/*.fasta | grep 'round_6'); do  
OutDir=$(dirname $Assembly)
echo "" > tmp.txt
ProgDir=~/git_repos/emr_repos/tools/seq_tools/assemblers/assembly_qc/remove_contaminants
$ProgDir/remove_contaminants.py --keep_mitochondria --inp $Assembly --out $OutDir/racon_min_500bp_renamed.fasta --coord_file tmp.txt > $OutDir/log.txt
done
```

Quast and busco were run to assess the effects of racon on assembly quality:

```bash
ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/assemblers/assembly_qc/quast
for Assembly in $(ls assembly/SMARTdenovo/*/*/racon_10/racon_min_500bp_renamed.fasta); do
Strain=$(echo $Assembly | rev | cut -f3 -d '/' | rev)
Organism=$(echo $Assembly | rev | cut -f4 -d '/' | rev)  
OutDir=$(dirname $Assembly)
qsub $ProgDir/sub_quast.sh $Assembly $OutDir
done
```

```bash
for Assembly in $(ls assembly/SMARTdenovo/*/*/racon_10/*.fasta | grep -e 'round_7.fasta' -e 'round_8.fasta' -e 'round_9.fasta' -e 'round_10.fasta'); do
Strain=$(echo $Assembly | rev | cut -f3 -d '/' | rev)
Organism=$(echo $Assembly | rev | cut -f4 -d '/' | rev)
echo "$Organism - $Strain"
ProgDir=/home/armita/git_repos/emr_repos/tools/gene_prediction/busco
BuscoDB=$(ls -d /home/groups/harrisonlab/dbBusco/embryophyta_odb10)
OutDir=gene_pred/busco/$Organism/$Strain/assembly
# OutDir=$(dirname $Assembly)
qsub $ProgDir/sub_busco3.sh $Assembly $BuscoDB $OutDir
done
```
```bash
printf "Filename\tComplete\tDuplicated\tFragmented\tMissing\tTotal\n"
for File in $(ls gene_pred/busco/*/*/assembly/*/short_summary_*.txt); do
FileName=$(basename $File)
Complete=$(cat $File | grep "(C)" | cut -f2)
Duplicated=$(cat $File | grep "(D)" | cut -f2)
Fragmented=$(cat $File | grep "(F)" | cut -f2)
Missing=$(cat $File | grep "(M)" | cut -f2)
Total=$(cat $File | grep "Total" | cut -f2)
printf "$FileName\t$Complete\t$Duplicated\t$Fragmented\t$Missing\t$Total\n"
done
```


For Stat10
```bash
# for Assembly in $(ls assembly/SMARTdenovo/*/*/racon_10/racon_min_500bp_renamed.fasta | grep -e 'Stat10'); do
# Strain=$(echo $Assembly | rev | cut -f3 -d '/' | rev)
# Organism=$(echo $Assembly | rev | cut -f4 -d '/' | rev)
# echo "$Organism - $Strain"
# # Step 1 extract reads as a .fq file which contain info on the location of the fast5 files
# # Note - the full path from home must be used
# ReadDir=raw_dna/nanopolish/$Organism/$Strain
# mkdir -p $ReadDir
# ReadsFq=$(ls raw_dna/minion/*/$Strain/*.fastq.gz)
# Fast5Dir=$(ls -d /data/seq_data/minion/2018/20180504_Statice10-180501/Statice10-180501/GA10000/reads)
# nanopolish index -v -d $Fast5Dir $ReadsFq
# done

for Assembly in $(ls assembly/SMARTdenovo/*/*/racon_10/racon_min_500bp_renamed.fasta | grep -e 'Stat10'); do
Strain=$(echo $Assembly | rev | cut -f3 -d '/' | rev)
Organism=$(echo $Assembly | rev | cut -f4 -d '/' | rev)
echo "$Organism - $Strain"
# Step 1 extract reads as a .fq file which contain info on the location of the fast5 files
# Note - the full path from home must be used

CurDir=$PWD
ScratchDir=/data/scratch/nanopore_tmp_data/Alternaria/albacore_v2.2.7

ReadDir=/data2/scratch2/armita/FoN/raw_dna/nanopolish/$Organism/$Strain
mkdir -p $ReadDir
cd $ReadDir
# tar -zxvf $ScratchDir/Stat10_2018-05-15_albacore_v2.2.7.tar.gz
cd $CurDir
Fast5Dir=$(ls -d /data2/scratch2/armita/FoN/raw_dna/nanopolish/F.oxysporum_fsp_statice/Stat10/home/nanopore/FoStatice_06-09-18/F.oxysporum_fsp_statice/Stat10/2018-05-15/albacore_v2.2.7/workspace/pass/unclassified/)

ReadsFq=raw_dna/minion/$Organism/$Strain/${Strain}_appended.fastq.gz
cat $Fast5Dir/*.fastq > $ReadsFq


nanopolish index -d $Fast5Dir $ReadsFq

OutDir=$(dirname $Assembly)/nanopolish
mkdir -p $OutDir
ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/assemblers/nanopolish
# submit alignments for nanoppolish
qsub $ProgDir/sub_minimap2_nanopolish.sh $Assembly $ReadsFq $OutDir/nanopolish
done
```


 Split the assembly into 50Kb fragments an submit each to the cluster for
 nanopolish correction

```bash
for Assembly in $(ls assembly/SMARTdenovo/*/*/racon_10/racon_min_500bp_renamed.fasta | grep -e 'Stat10'); do
Strain=$(echo $Assembly | rev | cut -f3 -d '/' | rev)
Organism=$(echo $Assembly | rev | cut -f4 -d '/' | rev)
echo "$Organism - $Strain"
OutDir=$(dirname $Assembly)/nanopolish
ReadsFq=$(ls raw_dna/minion/*/$Strain/*.fastq.gz | grep -v 'Stat10_2018-05-15')
AlignedReads=$(ls $OutDir/nanopolish/reads.sorted.bam)

NanoPolishDir=/home/armita/prog/nanopolish/nanopolish/scripts
python $NanoPolishDir/nanopolish_makerange.py $Assembly --segment-length 50000 > $OutDir/nanopolish_range.txt

Ploidy=1
echo "nanopolish log:" > $OutDir/nanopolish_log.txt
for Region in $(cat $OutDir/nanopolish_range.txt); do
Jobs=$(qstat | grep 'sub_nanopo' | grep 'qw' | wc -l)
while [ $Jobs -gt 1 ]; do
sleep 1m
printf "."
Jobs=$(qstat | grep 'sub_nanopo' | grep 'qw' | wc -l)
done		
printf "\n"
echo $Region
echo $Region >> $OutDir/nanopolish_log.txt
ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/assemblers/nanopolish
qsub $ProgDir/sub_nanopolish_variants.sh $Assembly $ReadsFq $AlignedReads $Ploidy $Region $OutDir/$Region
done
done
```

A subset of nanopolish jobs needed to be resubmitted as the ran out of RAM

```bash
for Assembly in $(ls assembly/SMARTdenovo/*/*/racon_10/racon_min_500bp_renamed.fasta | grep -e 'Stat10'); do
Strain=$(echo $Assembly | rev | cut -f3 -d '/' | rev)
Organism=$(echo $Assembly | rev | cut -f4 -d '/' | rev)
echo "$Organism - $Strain"
OutDir=$(dirname $Assembly)/nanopolish
# ReadsFq=$(ls raw_dna/minion/*/$Strain/*.fastq.gz | grep '2017-12-03')
ReadsFq=$(ls raw_dna/minion/*/$Strain/*.fastq.gz | grep -v 'Stat10_2018-05-15')
AlignedReads=$(ls $OutDir/nanopolish/reads.sorted.bam)

NanoPolishDir=/home/armita/prog/nanopolish/nanopolish/scripts
# python $NanoPolishDir/nanopolish_makerange.py $Assembly --segment-length 50000 > $OutDir/nanopolish_range.txt

Ploidy=1
echo "nanopolish log:" > $OutDir/nanopolish_high_mem_log.txt
ls -lh $OutDir/*/*.fa | grep -v ' 0 ' | cut -f8 -d '/' | sed 's/_consensus.fa//g' > $OutDir/files_present.txt
for Region in $(cat $OutDir/nanopolish_range.txt | grep -vwf "$OutDir/files_present.txt"); do
echo $Region
echo $Region >> $OutDir/nanopolish_high_mem_log.txt
Jobs=$(qstat | grep 'sub_nano_h' | grep 'qw' | wc -l)
while [ $Jobs -gt 1 ]; do
sleep 1m
printf "."
Jobs=$(qstat | grep 'sub_nano_h' | grep 'qw' | wc -l)
done		
printf "\n"
ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/assemblers/nanopolish
qsub $ProgDir/sub_nanopolish_variants_high_mem.sh $Assembly $ReadsFq $AlignedReads $Ploidy $Region $OutDir/$Region
done
done
```

```bash
for Assembly in $(ls assembly/SMARTdenovo/*/*/racon_10/racon_min_500bp_renamed.fasta | grep -e 'FON129' -e 'FON139' -e 'FON77' -e 'FON81' -e 'FON89'| grep -e 'FON81'); do
Strain=$(echo $Assembly | rev | cut -f3 -d '/' | rev)
Organism=$(echo $Assembly | rev | cut -f4 -d '/' | rev)
echo "$Organism - $Strain"
OutDir=assembly/SMARTdenovo/$Organism/$Strain/nanopolish
mkdir -p $OutDir
# cat "" > $OutDir/"$Strain"_nanoplish.fa
NanoPolishDir=/home/armita/prog/nanopolish/nanopolish/scripts
InDir=$(dirname $Assembly)
python $NanoPolishDir/nanopolish_merge.py $InDir/nanopolish/*/*.fa > $OutDir/"$Strain"_nanoplish.fa

echo "" > tmp.txt
ProgDir=~/git_repos/emr_repos/tools/seq_tools/assemblers/assembly_qc/remove_contaminants
$ProgDir/remove_contaminants.py --keep_mitochondria --inp $OutDir/"$Strain"_nanoplish.fa --out $OutDir/"$Strain"_nanoplish_min_500bp_renamed.fasta --coord_file tmp.txt > $OutDir/log.txt
done
```

Quast and busco were run to assess the effects of nanopolish on assembly quality:

```bash
for Assembly in $(ls assembly/SMARTdenovo/*/*/nanopolish/*_nanoplish_min_500bp_renamed.fasta | grep -e 'FON129' -e 'FON139' -e 'FON77' -e 'FON81' -e 'FON89' | grep -e 'FON81'); do
Strain=$(echo $Assembly | rev | cut -f3 -d '/' | rev)
Organism=$(echo $Assembly | rev | cut -f4 -d '/' | rev)  
# Quast
OutDir=$(dirname $Assembly)
ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/assemblers/assembly_qc/quast
qsub $ProgDir/sub_quast.sh $Assembly $OutDir
# Busco
BuscoDB=$(ls -d /home/groups/harrisonlab/dbBusco/sordariomyceta_odb9)
OutDir=gene_pred/busco/$Organism/$Strain/assembly
ProgDir=/home/armita/git_repos/emr_repos/tools/gene_prediction/busco
qsub $ProgDir/sub_busco3.sh $Assembly $BuscoDB $OutDir
done
```

```bash
  for File in $(ls gene_pred/busco/*/*/assembly/*/short_summary_*.txt); do
  Strain=$(echo $File| rev | cut -d '/' -f4 | rev)
  Organism=$(echo $File | rev | cut -d '/' -f5 | rev)
  Version=$(echo $File | rev | cut -d '/' -f2 | rev)
  Complete=$(cat $File | grep "(C)" | cut -f2)
  Single=$(cat $File | grep "(S)" | cut -f2)
  Fragmented=$(cat $File | grep "(F)" | cut -f2)
  Missing=$(cat $File | grep "(M)" | cut -f2)
  Total=$(cat $File | grep "Total" | cut -f2)
  echo -e "$Organism\t$Strain\t$Version\t$Complete\t$Single\t$Fragmented\t$Missing\t$Total"
  done
```
