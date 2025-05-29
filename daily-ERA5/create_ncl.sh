#!/bin/bash

# Loop through years 1950 to 2024
for year in {1950..2024}
do
    output_file="Lanczos_LF_${year}.ncl"
    
    # Write the script content
    cat > "$output_file" << EOL
year = ${year}

season = "SON"
month = (/8,9,10,11,12/)

clim_window = 31

varName = "z"

f = addfile("/g/data/if69/ls3248/data/ERA5/daily/"+varName+"/"+varName+"_era5_oper_pl_merge_1deg_daily_"+year+".nc","r")
date = cd_calendar(f->time,0)
time_ind = ind(date(:,1).eq.month(0) .or. date(:,1).eq.month(1) .or. date(:,1).eq.month(2) .or. date(:,1).eq.month(3) .or. date(:,1).eq.month(4))
var = f->\$varName\$(time_ind,:,:,:)
delete([/date,time_ind/])
print("data load")

;load 31 yr data file for climatology
f = addfile("/g/data/if69/ls3248/data/ERA5/daily/"+varName+"/climatology/"+varName+".ERA5."+season+".climatlogy.for."+year+".nc","r")
date = cd_calendar(f->time,0)
time_ind = ind(date(:,1).eq.month(0) .or. date(:,1).eq.month(1) .or. date(:,1).eq.month(2) .or. date(:,1).eq.month(3) .or. date(:,1).eq.month(4))
var_clim = f->\$varName\$(time_ind,:,:,:)
delete([/date,time_ind/])
print("data clim load")

;raw daily anom
var_anom = var - var_clim
copy_VarCoords(var, var_anom)

;filtered
dim = 0 ;the time dimension
nwt = 31
fca = 1./8.
fcb = -999.
ihp = 0 ;0-lowpass 1-highpass
nsigma = 1.
wts = filwgts_lanczos(nwt,ihp,fca,fcb,nsigma)
opt = 0
var_filtered  = wgt_runave_n_Wrap (var_anom, wts, opt, dim)

;extract targeted season
date = cd_calendar(var_anom&time,0)
time_ind = ind(date(:,1).eq.month(1) .or. date(:,1).eq.month(2) .or. date(:,1).eq.month(3))

out_file = varName+".ERA5."+season+".anom.LF."+year+".nc"
if (fileexists(out_file)) then
    system("rm -f "+out_file)
end if
f_out = addfile(out_file,"c")
f_out->\$varName\$ = var_filtered(time_ind,:,:,:)

delete([/date,time_ind/])

print(year+" is OK!")
EOL

    echo "Generated $output_file"
done