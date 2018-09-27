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
for Assembly in $(ls assembly/SMARTdenovo/*/*/*.dmo.lay.utg | grep 'F.oxysporum_fsp_lactucae' | grep 'AJ520'); do
  Strain=$(echo $Assembly | rev | cut -f2 -d '/' | rev)
  Organism=$(echo $Assembly | rev | cut -f3 -d '/' | rev)  
	echo "$Organism - $Strain"
  OutDir=$(dirname $Assembly)
	ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/assemblers/assembly_qc/quast
  qsub $ProgDir/sub_quast.sh $Assembly $OutDir
	OutDir=gene_pred/busco/$Organism/$Strain/assembly
	BuscoDB=$(ls -d /home/groups/harrisonlab/dbBusco/sordariomyceta_odb9)
	ProgDir=/home/armita/git_repos/emr_repos/tools/gene_prediction/busco
	qsub $ProgDir/sub_busco3.sh $Assembly $BuscoDB $OutDir
done
```
