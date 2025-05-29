#!/bin/bash

# Loop through years, 1950-1958 & after 1959, noting modifying the following $infile_Dir
for i in {1950..1958}
do
    output_file="cdo_daymean_remap_sellevel_${i}.sh"
    
    # Write the script content
    cat > "$output_file" << EOL
#!/bin/bash

var_Name="z"
level="10,20,30,50,70,100,150,175,200,225,250,300,400,500,600,700,800,850,900,925,950,1000"
month_String=("01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12") #set months
infile_Dir="/g/data/rt52/era5-preliminary/pressure-levels/reanalysis/\$var_Name" #path of hourly data (1950-1958) on Gadi
#infile_Dir="/g/data/rt52/era5/pressure-levels/reanalysis/\$var_Name" #path of hourly data (after 1959) on Gadi
outfile_Dir="/g/data/if69/ls3248/data/ERA5/daily/\$var_Name" #path of daily output data

i=${i}

for j in "\${month_String[@]}" #month loop
do
    echo "*****\$i\$j*****"
    #daymean
    cdo daymean \$infile_Dir"/"\$i"/"\$var_Name"_era5_oper_pl_"\$i\$j"*" \$outfile_Dir"/"\$var_Name"_era5_oper_pl_daily_"\$i\$j".nc"
    echo "daymean done"
    
    #remap
    cdo remapbil,r360x180 \$outfile_Dir"/"\$var_Name"_era5_oper_pl_daily_"\$i\$j".nc" \$outfile_Dir"/"\$var_Name"_era5_oper_pl_1deg_daily_"\$i\$j".nc"
    echo "remap done"
    rm -f \$outfile_Dir"/"\$var_Name"_era5_oper_pl_daily_"\$i\$j".nc"

    #select levels
    cdo sellevel,\$level \$outfile_Dir"/"\$var_Name"_era5_oper_pl_1deg_daily_"\$i\$j".nc" \$outfile_Dir"/"\$var_Name"_era5_oper_pl_1deg_daily_levels_"\$i\$j".nc"
    echo "level selected"
    rm -f \$outfile_Dir"/"\$var_Name"_era5_oper_pl_1deg_daily_"\$i\$j".nc"
done

#mergetime    
cdo mergetime \$outfile_Dir"/"\$var_Name"_era5_oper_pl_1deg_daily_levels_"\$i"*" \$outfile_Dir"/"\$var_Name"_era5_oper_pl_merge_1deg_daily_"\$i".nc"
rm -f \$outfile_Dir"/"\$var_Name"_era5_oper_pl_1deg_daily_levels_"\$i*
echo \$i" mergetime done"
EOL

    # Make the generated script executable
    chmod +x "$output_file"
    echo "Generated $output_file"
done