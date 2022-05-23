"""
Script split a vcf by chromosome. Read from stdin
"""
import argparse
import sys
import bgzip
import datetime


def time_check(msg):
    now = datetime.datetime.now()
    sys.stderr.write(now.strftime('%Y-%m-%d %H:%M:%S') + ": " + msg + chr(10))
    sys.stderr.flush()


parser = argparse.ArgumentParser()
parser.add_argument('--threads', help='Num threads for de/compression')
args = parser.parse_args()

threads = int(args.threads)
vcf_header = []
chrom = "placeholder"
chrom_out = None
raw_fh = None
for entry in sys.stdin:
    vcf_header.append(entry)
    if entry.startswith('#CHROM'):
        break
time_check("Finished getting header")
for entry in sys.stdin:
    if not entry.startswith(chrom):
        if entry.startswith('#FGQB'):
            time_check("Skipping line " + entry)
            continue
        if chrom_out:
            chrom_out.close()
        info = entry.split(chr(9))
        chrom = info[0]
        time_check("Writing vcf for " + chrom)
        raw_fh = open(chrom + ".vcf.gz", 'wb')
        chrom_out = bgzip.BGZipWriter(raw_fh, num_threads=threads)
        chrom_out.write("".join(vcf_header).encode('utf-8'))
    chrom_out.write(entry.encode('utf-8'))
chrom_out.close()
