#!/bin/bash

PROCSFILE='all_procs.txt'

DIR=${1%"/"}

echo -n "Building array with search terms... "
TERMS=()
while read line; do
	line_array=($line)
	PNS=${line_array[1]}
	PNAME=${line_array[2]}
	TERMS+=("${PNAME}")
	TERMS+=("${PNS}::${PNAME}")
done < ${PROCSFILE}
echo "Done."

for file in ${DIR}/*tcl; do
	echo -n "Scanning file: $file... "

	while read line; do
		[[ $line =~ ^proc.* ]] \
				&& CURRENTFUNC=$(echo $line | awk '{print $2}') \
				&& NEWPROC=1 \
				&& continue

		[[ $NEWPROC -eq 0 ]] \
				&& continue

		[[ $line =~ ^#.* ]] \
				&& continue

		[[ $line =~ ^namespace\ eval.* ]] \
				&& CURRENTNS=$(echo $line | awk '{print $3}') \
				&& continue

		for term in "${TERMS[@]}"; do
			if [[ $line =~ .*[:[\ ]${term}\ .* ]]; then
				echo "FOUND \"${term}\" IN \"${line}\""
				echo "${file} ${CURRENTNS} ${CURRENTFUNC}" >> $PROCSFILE
				NEWPROC=0
				continue
			fi
		done
	done < ${file}

	echo "Done."
done


