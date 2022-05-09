cwlVersion: v1.2
class: CommandLineTool
id: bcftools_sort_sample
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

      bcftools query -l
  - position: 2
    shellQuote: false
    valueFrom: >-
      | sort > samples.txt
  - position: 3
    shellQuote: false
    valueFrom: >-
      && bcftools view --force-samples samples.txt $(inputs.input_vcf.path) | bgzip -@ $(inputs.core) > sample_sorted_$(inputs.input_vcf.basename)
      && tabix sample_sorted_$(inputs.input_vcf.basename)

inputs:
  input_vcf: { type: File, doc: "bgzipped VCF file to sort samples in", inputBinding: { position: 1 }, secondaryFiles: ['.tbi']}
  cores: { type: 'int?', default: 8 } 

outputs:
  sample_sorted_vcf:
    type: File
    outputBinding:
      glob: '*.vcf.gz'
    secondaryFiles: ['.tbi']

