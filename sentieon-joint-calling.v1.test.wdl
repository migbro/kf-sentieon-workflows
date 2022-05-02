version 1.0

workflow sentieon_joint_genotyping {

    input {

        # gvcf and its index files
        Array[File] gvcfs_and_indices

        # Reference fasta and its indices
        Array[File] references

        # Reference fai for parallel region calculating
        File ref_fasta_index
            

        # Parallels 
        Int parallels = 3

        # output
        String output_vcf_gz = "final.vcf.gz"
    
    }

    call calculate_intervals {
        input: 
            ref_fasta_index = ref_fasta_index,
            parts = parallels,
    }

    scatter (index in range(parallels)) {

        # GVCFtype by region
        call shard_gvcf_typer {
            input:
                part_index = index,
                slice_shard_bed = calculate_intervals.slice_shards[index],
                all_shard = calculate_intervals.all_shards[index],
                gvcfs_and_indices = gvcfs_and_indices,
                references = references,
        }
    }

    call merge_vcf {
        input:
            input_vcfs = shard_gvcf_typer.shard_vcf,
            input_vcf_indices = shard_gvcf_typer.shard_vcf_index,
            output_vcf_gz = output_vcf_gz
    }

    output {
        File merged_vcf = merge_vcf.merged_vcf
        File merged_vcf_index = merge_vcf.merged_vcf_index
    }

}


task merge_vcf {

    input {

        Array[File] input_vcfs
        Array[File] input_vcf_indices

        String output_vcf_gz

        Int threads = 32
        String sentieon_version = "202010.01"
        String sentieon = "/home/release/sentieon-genomics-${sentieon_version}/bin/sentieon"
        String bcftools = "/home/zhipan/projects/bcftools-1.9/bcftools"

    }
    command <<<

        ~{sentieon} driver --passthru --algo GVCFtyper --merge ~{output_vcf_gz} ~{sep=" " input_vcfs}
    
    >>>

    output {
        File merged_vcf = output_vcf_gz
        File merged_vcf_index = output_vcf_gz + ".tbi"
    }

}

task shard_gvcf_typer {

    input{

        Int part_index
    
        Array[File] gvcfs_and_indices
        
        File slice_shard_bed
        String all_shard
        
        Array[File] references 
    
        Int threads = 32
        String sentieon_version = "202010.01"
        String sentieon = "/home/release/sentieon-genomics-${sentieon_version}/bin/sentieon"
        String bcftools = "/home/zhipan/projects/bcftools-1.9/bcftools"
    
    }

    String jointed_vcf = "joint-output-part" + part_index + ".vcf.gz"
    String jointed_vcf_index = "joint-output-part" + part_index + ".vcf.gz.tbi"
    
    command <<<

        # slice every sample gvcf by shard
        i=0
        cat ~{write_lines(gvcfs_and_indices)} | grep "g.vcf.gz$" | while read gvcf
        do
            sliced="sample-${i}.g.vcf.gz"
            echo "~{bcftools} view -R ~{slice_shard_bed} $gvcf | ~{sentieon} util vcfconvert - $sliced" >> cmd.txt        
            ((i=i+1))
        done

        cat cmd.txt | xargs -P ~{threads} -I % sh -c -f "%" || exit 1

        # All sample joint GVCFtyper on this shard
        ~{sentieon} driver -r ~{references[0]} --shard ~{all_shard} --algo GVCFtyper ~{jointed_vcf} sample-*.g.vcf.gz
    
    >>>

    output {
        Array[File] sliced_gvcfs = glob("sample-*.g.vcf.gz")
        File shard_vcf = jointed_vcf
        File shard_vcf_index = jointed_vcf_index
    }
}


task calculate_intervals {

    input {
        File ref_fasta_index
        Int parts
    }

    command <<<
        determine_shards_from_fai() {
            local bam parts tag chr len pos end
            fai="$1"
            parts="$2"
            margin=$3
            pos=$parts
            total=$(cat $fai |
            (while read chr len UR
            do
                pos=$(($pos + $len))
            done; echo $pos))
            step=$((($total-1)/$parts+1 ))

            pos=1
            cat $fai |\
            while read chr len other; do
                while [ $pos -le $len ]; do
                    end=$(($pos + $step - 1))
                    if [ $pos -lt 0 ]; then
                        start=1
                    else
                        start=$(($pos - $margin))
                        if [ $start -lt 1 ]; then
                            start=1
                        fi
                    fi
                    if [ $end -gt $len ]; then
                        echo -n "$chr:$start-$len,"
                        pos=$(($pos-$len))
                        break
                    else
                        echo "$chr:$start-$(($end + $margin))"
                        pos=$(($end + 1))
                    fi
                done
            done
            echo "NO_COOR"
        }
        create_shard_bed_from_fai() {
            local bam parts tag chr len pos end
            fai="$1"
            parts="$2"
            margin=$3
            fname_prefix="$4"
            idx=0
            pos=$parts
            total=$(cat $fai |
            (while read chr len UR
            do
                [ "${chr%%decoy}" != "$chr" ] && continue
                [ "${chr##HLA}" != "$chr" ] && continue
                [ "${chr%%alt}" != "$chr" ] && continue
                pos=$(($pos + $len))
            done; echo $pos))
            step=$((($total-1)/$parts+1 ))

            pos=0
            fname="$fname_prefix$idx.bed"
            echo $fname
            cat $fai |\
            while read chr len other; do
                [ "${chr%%decoy}" != "$chr" ] && continue
                [ "${chr##HLA}" != "$chr" ] && continue
                [ "${chr%%alt}" != "$chr" ] && continue
                while [ $pos -le $len ]; do
                    end=$(($pos + $step ))
                    if [ $pos -lt 0 ]; then
                        start=0
                    else
                        start=$(($pos - $margin))
                        if [ $start -lt 0 ]; then
                            start=0
                        fi
                    fi
                    if [ $end -gt $len ]; then
                        echo -e "$chr\t$start\t$len" >> $fname
                        pos=$(($pos-$len))
                        break
                    else
                        echo -e "$chr\t$start\t$(($end + $margin))" >> $fname
                        idx=$(($idx+1))
                        fname="$fname_prefix$idx.bed"
                        if [ "$idx" -lt "$parts" ]; then
                            echo $fname
                        fi
                        pos=$end
                    fi
                done
            done
        }
        determine_shards_from_fai ~{ref_fasta_index} ~{parts} 0 > shards.txt
        create_shard_bed_from_fai ~{ref_fasta_index} ~{parts} 200 "shard_" > shard_bed_files.txt
    >>>
   
    output {
        Array[String] all_shards = read_lines("shards.txt")
        Array[File] slice_shards = glob("shard_*.bed")
    }

}