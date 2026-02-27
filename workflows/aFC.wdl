version 1.0

task aFC {
    input {
        File vcf_file
        File vcf_index
        File expression_bed
        File expression_bed_index
        File covariates_file
        File afc_qtl_file
        String prefix

        Int memory
        Int disk_space
        Int num_threads
        Int num_preempt
    }

    Int actual_disk = ceil((size(vcf_file, "GB") + size(expression_bed, "GB"))) + disk_space

    command <<<
        echo "Running aFC.py..."
        python3 /opt/aFC/aFC.py \
            --vcf ~{vcf_file} \
            --pheno ~{expression_bed} \
            --qtl ~{afc_qtl_file} \
            --cov ~{covariates_file} \
            --log_xform 1 \
            --log_base 2 \
            --o ~{prefix}.aFC.txt

        gzip ~{prefix}.aFC.txt
    >>>

    runtime {
        docker: "gcr.io/broad-cga-francois-gtex/gtex_eqtl:V8"
        memory: "${memory}GB"
        disks: "local-disk ${actual_disk} HDD"
        cpu: num_threads
        preemptible: num_preempt
    }

    output {
        File afc_report = "${prefix}.aFC.txt.gz"
    }
}

workflow aFC_workflow {
    input {
        File vcf_file
        File expression_bed
        File covariates_file
        File afc_qtl_file
        String prefix
        Int memory = 16
        Int disk_space = 50
        Int num_threads = 8
        Int num_preempt = 0
    }

    call aFC {
        input:
            vcf_file = vcf_file,
            expression_bed = expression_bed,
            covariates_file = covariates_file,
            afc_qtl_file = afc_qtl_file,
            prefix = prefix,
            memory = memory,
            disk_space = disk_space,
            num_threads = num_threads,
            num_preempt = num_preempt
    }

    output {
        File final_afc_report = aFC.afc_report
    }
}
