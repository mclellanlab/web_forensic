#!/usr/bin/python

import os
import sys
import smtplib
import argparse
import subprocess
import traceback
from Bio import SeqIO

count_table = {}
sequence_to_asv_name = {}
sample_names = set([])


def main(task_path, task_id, region):
    infile = os.path.join(task_path, 'fasta.fa')
    outfile = os.path.join(task_path, 'counts_table.txt')
    region_file = os.path.join(task_path, 'region')
    email = open(os.path.join(task_path, 'email')).read().strip()

    for seq_record in SeqIO.parse("data/Gini_" + region + "_seq.fa", "fasta"):
        sequence = seq_record.seq
        count_table[str(sequence)] = {}
        sequence_to_asv_name[str(sequence)] = seq_record.id

    total_reads = 0
    reads_matched = 0

    for seq_record in SeqIO.parse(infile, "fasta"):
        total_reads += 1
        sequence = seq_record.seq
        sample_name = seq_record.id.split('|')[0]
        sample_names.add(sample_name)
        if sequence in count_table:
            if not sample_name in count_table[str(sequence)]:
                count_table[str(sequence)][sample_name] = 0

            count_table[str(sequence)][sample_name] += 1
            reads_matched += 1

    output = open(outfile, 'w')
    output.write("\t".join(sample_names) + "\n")

    for sequence in count_table:
        line = sequence_to_asv_name[str(sequence)] 

        for sample_name in sample_names:
            line += '\t' + str(count_table[str(sequence)].get(sample_name, 0))

        output.write(line + '\n')
    output.close()
    os.remove(infile)

    #-----------------------
    try:
        FROM_MAIL = "forensic.web.service@gmail.com"
        TO_MAIL = email

        server = smtplib.SMTP("smtp.gmail.com", 587)
        server.ehlo()
        server.starttls()
        server.login(FROM_MAIL, os.environ['SMTP_PASSWORD'])
        server.sendmail(FROM_MAIL, TO_MAIL, 
            """From: %s\nTo: %s\nSubject: Task is completed\n\nPlease go to %s view the report.""" % (FROM_MAIL, TO_MAIL, "http://165.227.73.45/result/" + task_id))
        server.close()
    except Exception as e:
        with open(os.path.join(task_path, 'email_failed'), 'w') as f:
            f.write(repr(e))
    #-------------------------

    if total_reads == 0:
        raise Exception("No reads found.")

    with open(region_file, 'w') as f:
        f.write(region)

    log = ""
    for script_path in ['R_scripts/1_RandomForest_UserDataset.R', 'R_scripts/2_Estimations_SourcesContribution.R', 'R_scripts/3_BrayCurtis.R']:
        counts_table = outfile
        report_file = os.path.join(os.path.dirname(outfile), 'report')
        command = ['Rscript', script_path, counts_table, report_file, region]

        log += "Running command: " + " ".join(map(str, command))
        try:
            stdout = subprocess.check_output(['Rscript', script_path, counts_table, report_file, region], stderr=subprocess.STDOUT)
            log += str(stdout) + "\n"
        except subprocess.CalledProcessError as e:
            log += "Return code: " + str(e.returncode) + "\n"
            log += str(e.output) + "\n"    

    with open(os.path.join(task_path, 'Rscript_logs.txt'), 'w') as logf:
        logf.write(log)

try:
    main(sys.argv[1], sys.argv[2], sys.argv[3])
except Exception as e:
    f = open(os.path.join(sys.argv[1], 'exit'), 'w')
    f.write(traceback.format_exc())
    f.close()


# # if script is ran by web service using Rscript
# # we are going to overwrite input and output variables
# args <- commandArgs(trailingOnly = TRUE)
# if (length(args) > 0) {
#     print(args)
#     User.Filename <- args[1]
#     GeneralOutputName <- args[2]
# }
