#!/bin/bash

PROCSFILE='all_procs.txt'

DIR=${1%"/"}

echo "Scanning folder ${DIR}"

for file in ${DIR}/*tcl
do
	echo -n "  file: $file"

	NAMESPACE=`grep "namespace eval" $file | awk '{print $3}'`

	echo " - namespace: $NAMESPACE"

	awk '/^proc /{print $2}' $file |
	awk -v fn="$file" -v ns="$NAMESPACE" -F "${NAMESPACE}::" '{print fn, ns, $2}' >> $PROCSFILE
done

echo "Done."

