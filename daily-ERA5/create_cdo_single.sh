#!/bin/bash

# Loop through years
for i in {1950..2024}
do
    output_file="cdo_daymean_remap_${i}.sh"
    
    # Write the script content
    cat > "$output_file" << EOL
#!/bin/bash

var_Name="msl"
month_String=("01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12") #set months
infile_Dir="/g/data/rt52/era5/single-levels/reanalysis/\$var_Name" 
outfile_Dir="/g/data/if69/ls3248/data/ERA5/daily/\$var_Name" #path of daily output data

i=${i}

for j in "\${month_String[@]}" #month loop
do
    echo "*****\$i\$j*****"
    #daymean
    cdo daymean \$infile_Dir"/"\$i"/"\$var_Name"_era5_oper_sfc_"\$i\$j"*" \$outfile_Dir"/"\$var_Name"_era5_oper_sfc_daily_"\$i\$j".nc"
    echo "daymean done"
    
    #remap
    cdo remapbil,r360x180 \$outfile_Dir"/"\$var_Name"_era5_oper_sfc_daily_"\$i\$j".nc" \$outfile_Dir"/"\$var_Name"_era5_oper_sfc_1deg_daily_"\$i\$j".nc"
    echo "remap done"
    rm -f \$outfile_Dir"/"\$var_Name"_era5_oper_sfc_daily_"\$i\$j".nc"
done

#mergetime    
cdo mergetime \$outfile_Dir"/"\$var_Name"_era5_oper_sfc_1deg_daily_"\$i"*" \$outfile_Dir"/"\$var_Name"_era5_oper_sfc_merge_1deg_daily_"\$i".nc"
rm -f \$outfile_Dir"/"\$var_Name"_era5_oper_sfc_1deg_daily_"\$i*
echo \$i" mergetime done"
EOL

    # Make the generated script executable
    chmod +x "$output_file"
    echo "Generated $output_file"
done