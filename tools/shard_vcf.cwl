cwlVersion: v1.2
class: CommandLineTool
id: shard_vcf
label: "Shard VCF File"
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'pgc-images.sbgenomics.com/d3b-bixu/vcfutils:latest'
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
          cmd += 'echo "bcftools view ' + inputs.input_vcf.path + ' -R ' + inputs.shard_bed[i].path + ' | bgzip > ' + slice + '" >> subset_cmd.txt;\n';
        }
        return cmd;
      }

      ${
        var cmd = "";
        for (var i=0; i < inputs.shard_bed.length; i++){
          var slice = inputs.input_vcf.nameroot.replace('.g.vcf','') + "-" + i + ".g.vcf.gz";
          cmd += 'echo "bcftools index --tbi ' + slice + '" >> index_cmd.txt;\n';
        }
        return cmd;
      }

      cat subset_cmd.txt | xargs -P $(inputs.cores) -I % sh -c -f "%" || exit 1

      cat index_cmd.txt | xargs -P $(inputs.cores) -I % sh -c -f "%" || exit 1

inputs:
  input_vcf: { type: File, doc: "bgzipped VCF file to shard.", secondaryFiles: ['.tbi']}
  shard_bed: { type: 'File[]', doc: "shard bed file array" }
  cores: { type: 'int?', default: 8 } 

outputs:
  sharded_vcf:
    type: 'File[]'
    outputBinding:
      glob: '*.g.vcf.gz'
    secondaryFiles: ['.tbi']

