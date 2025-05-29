#!/bin/bash

# 定义输出目录
output_dir="./"
# 循环范围
year_start=1950
year_end=2024

# 检查输出目录是否存在，若不存在则创建
mkdir -p "$output_dir" || { echo "错误：无法创建目录 $output_dir"; exit 1; }

# 循环生成脚本
for ((i=year_start; i<=year_end; i++)); do
    output_file="${output_dir}run_ncl_${i}.sh"
    
    # 写入PBS脚本内容
    cat > "$output_file" << EOF
#!/bin/bash

#PBS -P if69
#PBS -l ncpus=8
#PBS -l mem=16GB
#PBS -l storage=gdata/if69+gdata/rt52
#PBS -l wd
#PBS -e err${i}.info
#PBS -o out${i}.info

module load ncl/6.6.2

stdbuf -oL ncl Lanczos_LF_${i}.ncl > realtime_${i}.info 2>&1
EOF

    # 设置脚本为可执行
    chmod +x "$output_file" && echo "已生成：$output_file" || echo "错误：无法设置 $output_file 为可执行"
done