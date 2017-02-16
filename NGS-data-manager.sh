#!/bin/bash
## this script must be included in the crontab to be executed every certain amount of time, e.g. every 2 hours
## Check if there are any new runs in the folder corresponding to the sequencer, in this case the MiSeq Illumina sequencer
ls -d /data/ngsdata/MiSeq/*/ > /tmp/MiSeqDirs.txt
## For each new run, cycle through the steps to prepare the fastq files
for i in `cat /tmp/MiSeqDirs.txt`; do
	## Access the run folder
	cd /data/ngsdata/MiSeq/${i}
	## Check if the run has finished
	if [ -e RTAComplete.txt ]; then
		## check if it has been already demultiplexed
		if [ `ls Data/Intensities/BaseCalls/*.fastq.gz | wc -l` = 0 ]; then
			## if conditions are met, store in a variable the customer that own the project
			USER=`less SampleSheet.csv | grep "Investigator Name" | awk -F',' '{print $2}'`
			## run Illumina's demultiplexing software to generate the fastq files from the run folder with default parameters
			## more information on Illumina's bcl2fastq can be found at https://support.illumina.com/downloads/bcl2fastq-conversion-software-v217.html
			bcl2fastq
			## create a directory in the file system to generate a compressed folder containing only the generated fastq files
			mkdir /data/Customers/${i}_${USER}
			## copy the generated fastq files from the run folder to the customer's folder
			cp Data/Intensities/BaseCalls/*.gz /data/Customers/${i}_${USER}/
			## compress the customer's folder
			tar -zcvf /data/Customers/${i}_${USER}.tar.gz /data/Customers/${i}_${USER}/
			## create a link to the compressed folder in the apache2 server file hierarchy so the customer is able to download the data using a password protected (via htaccess) link
			ln -s /data/Customers/${i}_${USER}.tar.gz /var/www/html/${i}_${USER}.tar.gz
		fi
	fi
done
cd 
