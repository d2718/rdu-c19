#!/bin/bash

# Converts the alien UTF-16, tab-delimited raw downloads to a more
# civilized comma-delimited UTF-8.

set -euo pipefail

function fix {
  iconv -f UTF-16LE -t UTF-8 "$1" | \
    tr -d , | \
    tr "\t" , | \
    qsv input >"$2"
}

fix 'raw/Viral Gene Copies Persons.csv' viral.csv
fix 'raw/HOSPITAL_METRICS_STATE .csv' hospital.csv
