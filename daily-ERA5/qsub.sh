#!/bin/bash
for script in run_cdo_*.sh; do
    echo "Submitting $script..."
    qsub "$script"
done
