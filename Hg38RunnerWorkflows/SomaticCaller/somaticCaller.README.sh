#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 48:00:00

set -e; start=$(date +'%s'); rm -f FAILED COMPLETE QUEUED; touch STARTED

# 13 December 2019
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This tumor-normal workflow uses Illumina's Manta and Strelka2 variant callers to identify short INDELs and SNVs. 
# A tuned set of filtering statistics is applied to produce lists with different FDR tiers. 
# Lastly a panel of normals is used to remove systematic false positives due to high localized background. 
# It works best with tumor samples sequenced to >= 100x depth and >= 20x for the normal.  

#### Do just once ####

# 1) Install Singularity (https://www.sylabs.io) or load via a module, place in your path
module load singularity/3.5.1

# 2) Define file paths to "mount" in the container. The first is to the TNRunner data bundle downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/gnomexFlex.jsp?analysisNumber=A5578 . The second is the path to your data.
dataBundle=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner
myData=/scratch/mammoth/serial/u0028003

# 3) Modify the workflow xxx.sing file setting the paths to the required resources. These must be within the mounts.

# 4) Build the singularity container, and define the path to the xxx.sif file, do just once after each update.
#singularity pull docker://hcibioinformatics/public:SnakeMakeBioApps_5
container=/uufs/chpc.utah.edu/common/HIPAA/u0028003/HCINix/SingularityBuilds/public_SnakeMakeBioApps_5.sif

# 5) Create a file named vcfCallFreqConfig.txt containing a single line that defines the data files to scan for prior calling e.g. "fileFilter TAB Hg38/Somatic/Avatar/HA1" 


#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside somewhere in the myData mount path.

# 2) Soft link bam and bai files naming them tumor.bam, tumor.bai, normal.bam, and normal.bai into the analysis folder. 

# 3) Soft link passing read coverage bed files for the tumor and normal samples naming them tumor.bed.gz and normal.bed.gz into the analysis folder. 

# 4) Copy over the workflow docs: xxx.sing, xxx.README.sh, and xxx.sm into the job directory.

# 5) Launch the xxx.README.sh via slurm's sbatch or run it on your local server.  

# 6) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.



#### No need to modify anything below ####

echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# Read out params
name=${PWD##*/}
jobDir=`readlink -f .`

SINGULARITYENV_name=$name SINGULARITYENV_jobDir=$jobDir SINGULARITYENV_dataBundle=$dataBundle \
singularity exec --containall --bind $dataBundle,$myData $container \
bash $jobDir/*.sing

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

# Final cleanup
mkdir -p RunScripts
mv somaticCaller* RunScripts/
mv -f *.log  Logs/ || true
mv -f slurm* Logs/ || true
rm -rf .snakemake 
rm -f FAILED STARTED DONE RESTART
touch COMPLETE 

