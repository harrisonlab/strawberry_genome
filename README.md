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
	for RawReads in $(ls raw_dna/minion/*/*/*.fastq.gz | grep -v 'keygene'); do
    Organism=$(echo $RawReads | rev | cut -f3 -d '/' | rev)
    Strain=$(echo $RawReads | rev | cut -f2 -d '/' | rev)
    echo "$Organism - $Strain"
  	OutDir=qc_dna/minion/$Organism/$Strain
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
