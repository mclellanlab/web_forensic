#!/bin/sh

##### Check if CUTADAPT and PEAR are correctly installed. You shouldn't get an error message when running the commands below. If yes, please considering instal as advised on the respective websites.
cutadapt --version				# http://cutadapt.readthedocs.io/en/stable/
pear --version					# https://sco.h-its.org/exelixis/web/software/pear/


#####Parameters that can/have to be changed by the user #######################################################

# General parameters
workingPATH="PATH_TO_DIRECTORY"  	# Path to the parent directory. It is not the directory where are stored the fastqs. Should finish by "/"
fastq_directory="FASTQ_DIRECTORY"		# Name of the folder containing the fastqs. It must be located in the parent directory.
output_file="user_test.fa"	# Name of the output fasta
region="V6"					# 16S rRNA gene region targeted V4 or V6
reads_trimmed="yes"			# If sequences have been processed according to the Earth Microbiome protocol, the adaptors/primers have not been sequenced, the flag has thus to be set as "yes". 
R1="_R1"					# How can we discriminate R1 in the filename? _R1? _R1_?
R2="_R2"					# How can we discriminate R2 in the filename? _R2? _R2_?

removeCharacter=""			# Any character you want to delete between the Sample ID and the R1/R2 characters. Example: removeCharacter="_L001" for SampleID_L001_R1_blablabla.fastq.gz
threads=8					# Number of threads to use


# Warnings: R1 and R2 in your file must be frame by an underscore, if it is not the case, please ajust the line 65 to make the script fit your data. 
# 			Make sure that "_R1_" and "_R2_" are only present in the filenames to destinguish the R1 and R2 fastqs (and not part of the sample name).
##############################################################################################################





##############################
######### Preparation ######## 
##############################
cd "$workingPATH$fastq_directory"

	### Preparation
if [[ $region == "V6" ]]
then
	primerF="MNAMSCGMNRAACCTYANC"
	primerR="CGACRRCCATGCANCACCT"
	minlength=54
	maxlength=66
elif [[ $region == "V4" ]]
then
	primerF="CCAGCAGCYGCGGTAAN"
	primerR="GGACTACNVGGGTWTCTAATCC"
	minlength=230	
	maxlength=270
fi


if [[ $reads_trimmed="no" ]]
then
	mkdir ../Cutadapt/; printf "Creation of the directory ${workingPATH}Cutadapt/\n"
	mkdir ../PEAR/; printf "Creation of the directory ${workingPATH}PEAR/\n"
	mkdir ../fasta/; printf "Creation of the directory ${workingPATH}fasta/\n"
	mkdir ../PEAR/temp/


##############################
### Trimming with CUTADAPT ### 
##############################
	printf "\n\n### Trimming using Cutadapt ###\n"

	# Trim reads using cutadapt
	LOG_FILE_CUTADAPT="../Cutadapt/log_cutadapt.log"
	for fileR1 in *$R1*; do
	    fileR2=${fileR1/$R1/$R2}; printf "Trimming of ${fileR1} and ${fileR2} " 1>&3
		cutadapt -e 0.2 -m 50 -g "$primerF" -G "$primerR" -o "../Cutadapt/$fileR1" -p "../Cutadapt/$fileR2" $fileR1 $fileR2; printf "done\n" 1>&3
	done 3>&1 1>>${LOG_FILE_CUTADAPT} 2>&1
	printf "\n\n"

	# Export trimmed fastq in a temporary folder in order to be processed
	for file in ../Cutadapt/*; do cp ${file} ../PEAR/temp/; printf "Copied ${file}\n"; done
	cd ../PEAR/temp/

elif [[ $reads_trimmed="yes" ]]
then
	mkdir ../PEAR/; printf "Creation of the directory ${workingPATH}PEAR/\n"
	mkdir ../fasta/; printf "Creation of the directory ${workingPATH}fasta/\n"
	mkdir ../PEAR/temp/

	for file in *; do cp ${file} ../PEAR/temp/; printf "Copied ${file}\n"; done
	cd ../PEAR/temp/
else
 	echo "The flag 'reads_trimmed' is not correctly defined "
fi



###########################
#### Merging with PEAR ####
###########################

	# Preparation
for file in *.gz; do gzip -d ${file}; printf "Unzipped ${file}\n"; done
for i in *.fastq; do mv "$i" "${i/$removeCharacter/}"; done
qualitytrimming=0								# Quality score threshold for trimming the low quality part of a read. If the quality scores of two consecutive bases are strictly less than the specified threshold, the rest of the read will be trimmed. (default: 0)
basesN=0										# Maximal proportion of uncalled bases in a read. Setting this value to 0 will discard all reads containing uncalled bases (N). The other extreme setting is 1 which causes PEAR to process all reads independent on the number of uncalled bases. (default: 1)
LOG_FILE_PEAR="../log_PEAR.log"

	# Pair-end merging using pear
printf "\n\n### Merging using PEAR ###\n"

for fileR1 in *$R1*; do
    fileR2=${fileR1/$R1/$R2}
    file_o=${fileR1/$R1*.fastq/}; printf "Merging ${fileR1} and ${fileR2} " 1>&3
    pear -n $minlength -m $maxlength -q $qualitytrimming -u $basesN -j $threads -f $fileR1 -r $fileR2 -o  "../${file_o}"; printf "done\n" 1>&3
	rm -rf $fileR1 $fileR2 
done 3>&1 1>>${LOG_FILE_PEAR} 2>&1



################################
#### Convert fastq to fasta ####
################################
printf "\n\n ### Convert fastq to fasta ###\n"
cd ..

for file in *.assembled.fastq; do
	file_temp=${file/.*.fastq/.temp.fasta} # file_temp=${file/##*.fastq/.temp.fasta} with ## the character you want to use a the delineation in the header 
	cat $file | awk '{if(NR%4==1) {printf(">%s\n",substr($0,2));} else if(NR%4==2) print;}' > "$file_temp"; printf "${file_temp} generated\n"
done
printf "\n\n"



###############################################################
#### Change the header names with the name of the fasta file ####
###############################################################
for file in *.temp.fasta; do 
	file_o=${file/.temp.fasta/.fa}
	SampleName=${file/.temp.fasta/}
	awk '/>/{sub(">","&"FILENAME"|");sub(/\.temp.fasta/,x)}1' $file | awk '{print $1}' | awk '{gsub(/:/,"-")}1' > "$file_o"
done

rm -rf *temp.fasta



#############################################
#### Generation of the final multi-fasta ####
#############################################
cat *.fa > ../$output_file; printf "\n\n${workingPATH}${output_file} generated\n\n"




########################################
#### Clean and reorganize the mess! ####
########################################
for file in *.fastq; do gzip ${file}; printf "Zipped ${file}\n"; done
for file in *.fa; do cp ${file} ../fasta/${file}; printf "${workingPATH}fasta/${file} copied\n"; done


rm -rf *.fa
rm -r temp







