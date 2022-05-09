cwlVersion: v1.2
class: CommandLineTool
id: fix_vcf_header
doc: "Fixes header-compatibility and ensures sample sort consistency for merge step"
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'pgc-images.sbgenomics.com/hdchen/sentieon:202112.01_hifi'
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.cores)
    ramMin: $(inputs.cores * 1000)
  - class: EnvVarRequirement
    envDef:
    - envName: SENTIEON_LICENSE
      envValue: $(inputs.sentieon_license)
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
      
      python3 reheader_sort_samples.py
  - position: 2
    shellQuote: false
    valueFrom: >-
      | sentieon util vcfconvert - reheadered_$(inputs.input_vcf.basename)

inputs:
  input_vcf: { type: File, doc: "bgzipped VCF file to re-header.", inputBinding: { position: 1, prefix: '--input_vcf'}}
  phrase: { type: string, doc: "CSV partial-match phrases to exclude from header", inputBinding: { position: 1, prefix: '--phrase'} }
  marker: { type: boolean, doc: "File has sentieon marker line", inputBinding: { position: 1, prefix: "--marker"} }
  cores: { type: 'int?', default: 8 }
  sentieon_license: { type: string, doc: "Sentieon license file" }

outputs:
  fixed_vcf:
    type: File
    outputBinding:
      glob: '*.vcf.gz'
    secondaryFiles: ['.tbi']

