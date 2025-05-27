import os
import json
import requests
from urllib.parse import urlparse
from tqdm import tqdm

# Mapping for short type codes to full type names
type_map = {
    'A': 'atmosphere',
    'O': 'ocean',
    'OI': 'seaice',
}

# Mapping frequency codes to descriptive names
freq_map = {
    'mon': 'monthly',
    'day': 'daily',
}

# Path to JSON file with URL lists
json_path = '/g/data/su28/MMLEAv2/code/all_backup.json'

# Base directory to store downloads
base_dir = '/g/data/su28/MMLEAv2/'
os.makedirs(base_dir, exist_ok=True)

# Open the JSON and load the file lists
all_urls = []
with open(json_path) as f:
    filelists = json.load(f)
    for urls in filelists.values():
        all_urls.extend(urls)

# Log file for any download failures
with open('failed.txt', 'a') as fail:
    with tqdm(total=len(all_urls), desc="Downloading files") as pbar:
        for url in all_urls:
            try:
                print(f"\nProcessing: {url}")
                parsed = urlparse(url)
                parts = parsed.path.strip('/').split('/')

                # Expecting something like: access_lens/Amon/evspsbl/filename.nc
                if len(parts) < 4:
                    raise Exception("Unexpected URL format")

                freq_code = parts[-3]  # e.g., Amon
                var = parts[-2]        # e.g., evspsbl
                filename = os.path.basename(url)

                # Update tqdm with current filename
                pbar.set_description(f"Downloading {filename[:40]}")

                # Extract metadata
                type_code = freq_code[0]     # A from Amon
                freq_suffix = freq_code[1:].lower()  # mon from Amon
                model = filename.split('_')[2]  # e.g., ACCESS-ESM1-5

                type_name = type_map.get(type_code.upper(), 'unknown')
                freq_name = freq_map.get(freq_suffix, freq_suffix)

                # Build output path
                dest_dir = os.path.join(base_dir, type_name, freq_name, var, model)
                os.makedirs(dest_dir, exist_ok=True)

                dest_file = os.path.join(dest_dir, filename)

                # Skip if file already exists
                if os.path.exists(dest_file):
                    #print(f"Already exists: {dest_file} — skipping.")
                    pbar.update(1)
                    continue

                # Download file
                response = requests.get(url, allow_redirects=True, timeout=60)
                response.raise_for_status()

                with open(dest_file, 'wb') as f_out:
                    f_out.write(response.content)
                #print(f"Saved to: {dest_file}")

            except Exception as e:
                print(f"Failed: {url} — {e}")
                fail.write(url + '\n')
            finally:
                pbar.update(1)