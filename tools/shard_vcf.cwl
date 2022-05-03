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

      ${
        var cmd = "";
        for (var i=0; i < inputs.shard_bed.length; i++){
          var slice = inputs.input_vcf.nameroot.replace('.g.vcf','') + "-" + i + ".g.vcf.gz";
          cmd += 'echo "bcftools view ' + inputs.input_vcf.path + ' -R ' + inputs.shard_bed[i].path + ' -O z > ' + slice + '" >> cmd.txt;';
        }
      }

      cat cmd.txt | xargs -P $(inputs.cores) -I % sh -c -f "%" || exit 1

inputs:
  input_vcf: {type: File, doc: "VCF file to shard."}
  shard_bed: { type: 'File[]', doc: "shard bed file array" }
  cores: { type: 'int?', default: 8 } 

outputs:
  sharded_vcf:
    type: 'File[]'
    outputBinding:
      glob: '*.g.vcf.gz'

