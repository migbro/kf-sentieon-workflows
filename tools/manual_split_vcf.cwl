cwlVersion: v1.2
class: CommandLineTool
id: manual_split_by_chr
doc: "Splits bgzipped vcf by chromosome"
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'migbro/vcf_general_utils'
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.cores)
    ramMin: $(inputs.cores * 1000)
  - class: InitialWorkDirRequirement
    listing:
    - entryname: manual_split_by_chr.py
      writable: false
      entry:
        $include: ../scripts/manual_split_by_chr.py

baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -eo pipefail

      bgzip -dc $(inputs.input_vcf.path) -@ $(inputs.cores/2) | python3 manual_split_by_chr.py --threads $(inputs.cores/2)
  - position: 2
    shellQuote: false
    valueFrom: >-
      && ls *.vcf.gz | xargs -IFN -P $(inputs.cores) tabix FN

inputs:
  input_vcf: { type: File, doc: "bgzipped VCF file to split."}
  cores: { type: 'int?', default: 8 }

outputs:
  split_vcfs:
    type: File[]
    outputBinding:
      glob: '*.vcf.gz'
    secondaryFiles: ['.tbi']

