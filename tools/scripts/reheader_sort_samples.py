"""
Script to re-header output from sentieon and sort columns by sample
"""
import argparse
import sys
import gzip
import pdb

parser = argparse.ArgumentParser()
parser.add_argument('--input_vcf', help='VCF process')
parser.add_argument('--phrase', help='CSV string of phrases to remove from header')
parser.add_argument('--marker', action='store_true', help='Flag if sentieon marker present')
args = parser.parse_args()

vcf = gzip.open(args.input_vcf)

sample_header = ""
samp_map = []
phrases = args.phrase.split(',')
for line in vcf:
    entry = line.decode()
    if entry.startswith('#CHROM'):
        sample_header = entry
        info = entry.rstrip(chr(10)).split(chr(9))
        sorted_samples = info[9:]
        unsorted_samples = info[9:]
        sorted_samples.sort()
        for bs_id in sorted_samples:
            samp_map.append(unsorted_samples.index(bs_id))
        sys.stdout.write(chr(9).join(info[0:9]) + chr(9) + chr(9).join([unsorted_samples[i] for i in samp_map]) + chr(10))
        break
    else:
        skip = 0
        for phrase in phrases:
            if phrase in entry:
                skip = 1
                break
        if not skip:
            sys.stdout.write(entry)
# output extra file marker if present
if args.marker:
    marker = next(vcf)
    sys.stdout.write(marker.decode())
for calls in vcf:
    info = calls.decode().rstrip(chr(10)).split(chr(9))
    sys.stdout.write(chr(9).join(info[0:9]) + chr(9) + chr(9).join([info[9:][i] for i in samp_map]) + chr(10))
