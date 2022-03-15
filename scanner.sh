#!/bin/bash

# This script searches for "needles" in all applications that belong in "haystack" app-categories.

# Output file. Duh!
output_file="report.csv"

# A list of search terms
needles="taccttaxeventbet tappmt tasyncbetlegoff tasyncbetoff tbet tbetasync tbetblockbuster tbetcashout tbetclientdetail tbetextrainfo tBetHist tbetlegreturn tbetlinestl tbetlinestltax tbetoverride tbetoverridemaxbet tBetReStl tBetSlip tBetSlipBet tBetStl tbetstlpending tbettag tbetterms tBetUnStl tbforder tbfpassbet tbfpassunstlbet tbirbet tbirbettoken tbirobet tbirreq tcryptosubinfo tcustbetoverride tcusttokredemption tfbetcustadj thedgedbet tjrnl tliabengmsg tliabengrumbet tliabengrumobet tliabsglexotic tmanobet tobet tobetaltresult tobetextrainfo toBetHist toBetResult tobettag toncourserepbet toverride tpossiblebet tredemptionval trsmsg tsgbet tsgbetcashout tsgbetcashoutresponse tsgbetresponse tsgrequest tstlbetfail tstreamingvideo ttimlbet ttimlobet tvegassubinfo tvscust tvsgroupcust txsyssubxfer txsyssyncxfer txsysxfer txsysxferlink txsysxferlinkparam txsysxferlinktransitional txsysxfertranlnk"

# A list of application categories
haystack="standalone backoffice product shared"

echo "Application|Table|Files|" > ${output_file}

for cat in $haystack; do
	for folder in ${cat}*; do
		# loop through applications
		for table in $needles; do
			# loop through tables
			files=`grep -rwin ${table} ${folder} | grep "/src/" | grep -v "/src/conf/" | grep -v "/src/doc/" | awk -F ":" '{print $1 }' | uniq`
			if [ "$files" != "" ]; then
				#echo -e "${table} found in:\n${files}"
				echo "${folder}|${table}|\"${files}\"|" >> ${output_file}
			fi
		done
	done
done
