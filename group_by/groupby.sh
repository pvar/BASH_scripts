#!/bin/bash

input_file="test.csv"

output_file="grouped_${input_file}"

# field to use for grouping
GRPBYIDX=3

# field to group
GRPIDX=5

file="./test.csv"

{
	# copy the first line of the original file into the new one
	read -r line
	echo -n "$line" > "$output_file"

	# loop through the rest of the lines...
	last_groupby_value=""
	while read -r line
	do
		# explode read line into an array of strings
		# separator is specified through IFS environment variable
		IFS=','
		fields=($line)

		this_groupby_value=${fields[$GRPBYIDX]}
		if [[ $this_groupby_value == $last_groupby_value ]]; then
			# append Exchange Selection to last line
			echo -n "${fields[$GRPIDX]}," >> "$output_file"
		else
			# create new line
			echo -n -e "\n${fields[0]},${fields[1]},${fields[2]},${fields[3]},${fields[4]},${fields[$GRPIDX]}," >> "$output_file"
		fi
		last_groupby_value=$this_groupby_value
	done 
} < "$input_file"
