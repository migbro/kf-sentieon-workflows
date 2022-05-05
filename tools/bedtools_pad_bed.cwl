cwlVersion: v1.2
class: CommandLineTool
id: bedtools_pad_bed
label: "Pad Bed File"
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
        for (var i=0; i < inputs.input_bed.length; i++){
          var padded = inputs.input_bed[i].nameroot + "_padded_" + inputs.pad + ".bed";
          cmd += 'echo "bedtools slop -i ' + inputs.input_bed[i].path + ' -b ' + inputs.pad + ' -g '
          + inputs.genome.path + ' | bedtools sort | bedtools merge >' + padded + '" >> cmd.txt;';
        }
        return cmd;
      }

      cat cmd.txt | xargs -P $(inputs.cores) -I % sh -c -f "%" || exit 1

inputs:
  input_bed: { type: 'File[]', doc: "Array of bed files to pad." }
  pad: { type: int, doc: "number of base pairs to pad" }
  genome: { type: File, doc: "tsv file with chromosome and length"}
  cores: { type: 'int?', default: 8 } 

outputs:
  padded_bed:
    type: 'File[]'
    outputBinding:
      glob: '*.bed'
  cmd_file:
    type: File
    outputBinding:
      glob: 'cmd.txt'

