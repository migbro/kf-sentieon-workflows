"""
Script to re-header output from sentieon and sort columns by sample
"""
import argparse
import sys
import gzip
import datetime


def time_check(msg):
    now = datetime.datetime.now()
    sys.stderr.write(now.strftime('%Y-%m-%d %H:%M:%S') + ": " + msg + chr(10))
    sys.stderr.flush()
 

def print_sorted(call):
    try:
        info = call.decode().rstrip(chr(10)).split(chr(9))
        print(chr(9).join(info[0:9]) + chr(9) + chr(9).join([info[9:][i] for i in samp_map]))
    except Exception as e:
        sys.stderr.write(str(e) + chr(10))
        sys.stderr.write('Output failed likely due to file marker, outputting marker and skip sample sort' + chr(10))
        sys.stdout.write(call.decode())


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
time_check("Finished fixing header, outputting all entries with samples sorted")
x = 1
n = 10000

for calls in vcf:
    print_sorted(calls)
    if x % n == 0:
        time_check("Processed " + str(x) + " calls")
    x += 1
