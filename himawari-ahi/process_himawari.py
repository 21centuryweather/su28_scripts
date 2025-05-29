###########################################
# Process cloud type data from 
# /g/data/rv74/satellite-products/arc/der/himawari-ahi/cloud/ct
#
# * Include the timestamp as a dimension 
# * Converted nx/ny to lat/lon coordinates
# * Plot result
#
# Contributors: 
# * Samuel Green - ORCID 0000-0003-1129-4676
# * Mat Lipson - ORCID 0000-0001-5322-1796
# * Kimberley Reid - ORCID 0000-0001-5972-6015
###########################################

import xarray as xr
import re
import pandas as pd
import numpy as np
import rioxarray as rxr
import glob
import os

# Plotting stuff:
import matplotlib.pyplot as plt
from matplotlib import colormaps
import matplotlib.colors as mcolors
from matplotlib.colors import LinearSegmentedColormap, TwoSlopeNorm
import matplotlib.cm as cm
import cartopy.crs as ccrs
import cartopy.feature as cft
import cmocean as cmo
import matplotlib as mpl
import matplotlib.ticker as mticker

import dask
from dask.distributed import Client

client = Client()
client

# Function to extract timestamp from filename
def extract_timestamp(filename):
    match = re.search(r"_(\d{8}T\d{6})Z", filename)
    if match:
        timestamp = pd.to_datetime(match.group(1), format="%Y%m%dT%H%M%S")
        return timestamp.replace(second=0, microsecond=0)
    return None


def open_and_add_time(file):
    #O\open files
    ds = rxr.open_rasterio(file, chunks={"x": 1024, "y": 1024}, masked=True)[0]
    #reproject to lat/lon
    da = ds.rio.reproject('epsg:4326')
    timestamp = extract_timestamp(os.path.basename(file))

    # Add time dimension
    da = da.expand_dims(time=[timestamp])  # Add time as a new dimension

    return da

file_list = sorted(glob.glob("/g/data/rv74/satellite-products/arc/der/himawari-ahi/cloud/ct/latest/2022/01/01/S_NWC_CT*"))

# Delayed open and timestamp attach
delayed_datasets = [dask.delayed(open_and_add_time)(f) for f in file_list]
# Trigger Dask to load data
datasets = dask.compute(*delayed_datasets)
# Concatenate along time
stacked = xr.concat(datasets, dim="time")
# rename to lat/lon
stacked = stacked.rename({"x": "lon", "y": "lat"})
# slice lat/lon to have the  Australian regional domain
stacked1 = stacked.sel(lat=slice(19.425, -64.945), lon=slice(65.055, 196.945))
# set the names for all the cloud types
comment = '1:  Cloud-free land; 2:  Cloud-free sea; 3:  Snow over land;  4:  Sea ice; 5:  Very low clouds; 6:  Low clouds; 7:  Mid-level clouds;  8:  High opaque clouds; 9:  Very high opaque clouds;  10:  Fractional clouds; 11:  High semitransparent thin clouds;  12:  High semitransparent moderately thick clouds;  13:  High semitransparent thick clouds;  14:  High semitransparent above low or medium clouds;  15:  High semitransparent above snow/ice'

# Use regex to extract values and labels
matches = re.findall(r'(\d+):\s+([^;]+)', comment)

# Convert to dictionary
category_dict = {int(num): desc.strip() for num, desc in matches}

# Print result
for k, v in sorted(category_dict.items())[:14]:
    print(f"{k}: {v}")

fig = plt.figure(figsize=(16, 8))

ax = plt.axes(projection=ccrs.PlateCarree(central_longitude=130))
ax.coastlines(resolution="50m", color='white')

# Define the values and corresponding colors from tab20
values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]  # Adjust based on your dataset
# Set the min and max colors from tab20
min_color = mpl.colormaps['tab20'](0 / 20)
max_color = mpl.colormaps['tab20'](19 / 20)  # Last color of tab20

# Generate intermediate colors by linearly spacing them within tab20
num_classes = len(values)
colors = [mpl.colormaps['tab20'](i / (num_classes - 1)) for i in range(num_classes)]

# Ensure min/max colors are set explicitly
colors[0] = min_color
colors[-1] = max_color

# Create discrete colormap
cmap = mcolors.ListedColormap(colors)
# Define boundaries for normalization (each value gets its own bin)
boundaries = np.arange(min(values) - 0.5, max(values) + 1.5, 1)  # Adjusted for correct binning
norm = mcolors.BoundaryNorm(boundaries, cmap.N)

img = stacked1.sel(time='2022-01-01T03:00:00.000000000').ct.plot(ax=ax, x="lon", y="lat", transform=ccrs.PlateCarree(), cmap=cmap, norm=norm, add_colorbar=False)

# Add a discrete colorbar
cbar = fig.colorbar(img, ax=ax, orientation="vertical", fraction=0.03, pad=0.02)
cbar.set_label("Cloud Type (CT)", fontsize=12)
cbar.set_ticks(values)  # Ensure ticks match category values
cbar.set_ticklabels([f"{k}: {v}" for k, v in sorted(category_dict.items())[:14]])  # Custom labels

# Add gridlines with labels
gl = ax.gridlines(draw_labels=True, linestyle="--", linewidth=1.0)
gl.top_labels = False  # Disable top labels
gl.right_labels = False  # Disable right labels

# Increase the number of ticks on the x-axis
gl.xlocator = mticker.FixedLocator(np.arange(70, 190, 20))  # Adjust step size as needed
