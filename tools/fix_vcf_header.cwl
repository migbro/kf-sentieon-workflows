cwlVersion: v1.2
class: CommandLineTool
id: fix_vcf_header
doc: "Fixes header-compatibility and ensures sample sort consistency for merge step"
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
    - entryname: reheader_sort_samples.py
      writable: false
      entry:
        $include: ../scripts/reheader_sort_samples.py

baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -eo pipefail
      
      /pypy3.8-v7.3.9-linux64/bin/pypy3 reheader_sort_samples.py
  - position: 2
    shellQuote: false
    valueFrom: >-
      | bgzip -@ ${return inputs.cores - 1;} -c  > reheadered_$(inputs.input_vcf.basename)
  - position: 3
    shellQuote: false
    valueFrom: >-
      && tabix reheadered_$(inputs.input_vcf.basename)


inputs:
  input_vcf: { type: File, doc: "bgzipped VCF file to re-header.", inputBinding: { position: 1, prefix: '--input_vcf'}}
  phrase: { type: string, doc: "CSV partial-match phrases to exclude from header", inputBinding: { position: 1, prefix: '--phrase'} }
  marker: { type: boolean, doc: "File has sentieon marker line", inputBinding: { position: 1, prefix: "--marker"} }
  cores: { type: 'int?', default: 8 }

outputs:
  fixed_vcf:
    type: File
    outputBinding:
      glob: '*.vcf.gz'
    secondaryFiles: ['.tbi']

