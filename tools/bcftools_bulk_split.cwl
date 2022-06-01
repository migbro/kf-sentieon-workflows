cwlVersion: v1.2
class: CommandLineTool
id: bcftools_bulk_split
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'pgc-images.sbgenomics.com/d3b-bixu/vcfutils:latest'
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.cores)
    ramMin: $(inputs.cores * 1000)

baseCommand: []
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-      
      cut -f 1 $(inputs.chr_list.path)
      ${
          if(inputs.top_n){
              return "| head -n " + inputs.top_n;
          }
          else{
              return "";
          }
      }
      | xargs -ICN -P $(inputs.cores) bcftools view -O z -o CN.vcf.gz $(inputs.input_vcf.path) CN
      && ls *.vcf.gz | xargs -IFN -P $(inputs.cores) tabix FN

inputs:
  input_vcf: { type: File, doc: "bgzipped VCF file split", secondaryFiles: ['.tbi']}
  chr_list: { type: File, doc: "New-line separated file with contig names to split on - can also be .fai file" }
  top_n: { type: 'int?', doc: "Set limit to number of chr from file to use", default: 24}
  cores: { type: 'int?', default: 16 } 

outputs:
  split_vcfs:
    type: 'File[]'
    outputBinding:
      glob: '*.vcf.gz'
    secondaryFiles: ['.tbi']

