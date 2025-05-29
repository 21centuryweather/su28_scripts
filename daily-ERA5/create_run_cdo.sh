#!/bin/bash

output_dir="./"
year_start=1950
year_end=2024

mkdir -p "$output_dir" || { echo "error: cannot create folder $output_dir"; exit 1; }

for ((i=year_start; i<=year_end; i++)); do
    output_file="${output_dir}run_cdo_${i}.sh"
    
    cat > "$output_file" << EOF
#!/bin/bash

#PBS -P if69
#PBS -l ncpus=8
#PBS -l mem=16GB
#PBS -l storage=gdata/if69+gdata/rt52
#PBS -l wd
#PBS -e err${i}.info
#PBS -o out${i}.info

stdbuf -oL bash cdo_daymean_remap_sellevel_${i}.sh > realtime_${i}.info 2>&1
EOF
    chmod +x "$output_file" && echo "created: $output_file" || echo "error: $output_file not created"
done