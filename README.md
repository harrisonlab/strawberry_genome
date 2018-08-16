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
$ProgDir/sub_canu_correct.*.fastq.sh
```
