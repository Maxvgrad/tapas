#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 input_file output_file percent"
    exit 1
fi

# Get the arguments
input_file="$1"
output_file="$2"
percent="$3"

# Calculate the total number of lines
total_lines=$(wc -l < "$input_file")

# Calculate the number of lines to extract
num_lines=$((total_lines * percent / 100))

# Extract the specified percentage of lines and save to the output file
head -n "$num_lines" "$input_file" > "$output_file"

# Compress the output file
gzip -c "$output_file" > "${output_file}.gz"

# Optional: remove the intermediate output file if you don't need it
#rm "$output_file"

echo "The first $percent% of lines ($num_lines) have been extracted and archived as ${output_file}.gz"
