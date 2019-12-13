#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 96:00:00

set -e; start=$(date +'%s'); rm -f FAILED COMPLETE QUEUED; touch STARTED

# 13 December 2019
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This is a Unique Molecular Index Barcode (UMI) aware BWA mem alignment to Hg38/GRCh38 followed by USeq Consensus calling on alignments with the same UMI and unclipped start position, quality filtering, base score recalibration, haplotype calling, and various QC calculations.
# Run the USeq AggregateQCStats app on a directory containing multiple alignment runs to combine all the QC results into several relevant QC reports.


#### Do just once ####

# 1) Install Singularity (https://www.sylabs.io) or load via a module, place in your path
module load singularity/3.5.1

# 2) Define file paths to "mount" in the container. The first is to the TNRunner data bundle downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/gnomexFlex.jsp?analysisNumber=A5578 . The second is the path to your data.
dataBundle=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner
myData=/scratch/mammoth/serial/u0028003

# 3) Modify the workflow xxx.sing file setting the paths to the required resources. These must be within the mounts.

# 4) Build the singularity container, and define the path to the xxx.sif file, do just once after each update.
#singularity pull docker://hcibioinformatics/public:SnakeMakeBioApps_4
container=/uufs/chpc.utah.edu/common/HIPAA/u0028003/HCINix/SingularityBuilds/public_SnakeMakeBioApps_4.sif


#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside somewhere in the myData mount path.

# 2) Soft link your paired read and inline 3mer UMI fastq.gz files into the job dir naming them 1.fastq.gz, 2.fastq.gz

# 3) Copy over the workflow docs: xxx.sing, xxx.README.sh, and xxx.sm into the job directory.

# 4) Add a file named sam2USeq.config.txt that contains a single line of params for the Sam2USeq tool, e.g. -c 10, or -c 20 to define the minimum read coverage for the normal or tumor samples respectively.

# 5) Launch the xxx.README.sh via sbatch or run it on your local server.  

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
mv dnaConsensusAlignQC* RunScripts/
mv sam2USeq.config.txt RunScripts/
mv -f *.log  Logs/ &> /dev/null || true
mv -f slurm* Logs/ &> /dev/null || true
rm -rf .snakemake 
rm -f FAILED STARTED DONE RESTART
touch COMPLETE 
