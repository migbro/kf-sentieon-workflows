cwlVersion: v1.2
class: CommandLineTool
id: shard_vcf
label: "Shard VCF File"
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'pgc-images.sbgenomics.com/hdchen/sentieon:202112.01_hifi'
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.cores)
    ramMin: $(inputs.cores * 1000)

baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -eo pipefail

      i=0
      cat $(inputs.shard_intervals) | while read slice
      do
          sliced="$(inputs.input_vcf.nameroot.replace('.g.vcf',''))-$i.g.vcf.gz"
          echo "bcftools view -r $slice $(inputs.input_vcf.path) | sentieon util vcfconvert - $sliced" >> cmd.txt        
          i=`expr $i + 1`
      done

      cat cmd.txt | xargs -P $(inputs.cores) -I % sh -c -f "%" || exit 1

inputs:
  input_vcf: {type: File, doc: "VCF file to shard."}
  shard_intervals: { type: File, doc: "output file from generate_shards" }
  cores: { type: 'int?', default: 8 } 


outputs:
  sharded_vcf:
    type: 'File[]'
    outputBinding:
      glob: '*.g.vcf.gz'

