#!/bin/bash
 
while [[ $BRAND != "1" && $BRAND != "2" && $BRAND != "0" ]]; do
    echo "Choose the brand to discover available boxes"
    echo "1) PPB (you must be in a vasco box)"
    echo "2) FD  (you must be running this script from a dev server)"
    echo "0) Abort!"
    read -p "Your choice: " BRAND
done

if [[ $BRAND == "1" ]]; then
    BRAND="PPB"
elif [[ $BRAND == "2" ]]; then
    BRAND="FD"
else
    exit
fi

declare -a app_names;                     declare -A app_codes;
app_names+=( "admin" );                   app_codes["admin"]="obadm"
app_names+=( "bet_auth" ) ;               app_codes["bet_auth"]="obbac"
app_names+=( "bet_voider" );              app_codes["bet_voider"]="obbv"
app_names+=( "bulletin_fbr" );            app_codes["bulletin_fbr"]="obbulfbr"
app_names+=( "bulletin_fmg" );            app_codes["bulletin_fmg"]="obbulfmg"
app_names+=( "dbPublish" );               app_codes["dbPublish"]="obpub"
app_names+=( "dw_forwarder" );            app_codes["dw_forwarder"]="obdwf"
app_names+=( "dw_reporter" );             app_codes["dw_reporter"]="obdw"
app_names+=( "event_manager" );           app_codes["event_manager"]="obem"
app_names+=( "feed_bf_exchange" );        app_codes["feed_bf_exchange"]="obfhex"
app_names+=( "feed_fmm" );                app_codes["feed_fmm"]="obfhfmm"
app_names+=( "feed_misc" );               app_codes["feed_misc"]="obfhmsc"
app_names+=( "feed_ti" );                 app_codes["feed_ti"]="obfhti"
app_names+=( "gdprcs" );                  app_codes["gdprcs"]="obgcs"
app_names+=( "jms" );                     app_codes["jms"]="objmsp"
app_names+=( "jms_it" );                  app_codes["jms_it"]="objmspit"
app_names+=( "liability_engine" );        app_codes["liability_engine"]="oble"
app_names+=( "liveserv" );                app_codes["liveserv"]="obls"
app_names+=( "office" );                  app_codes["office"]="oboff"
app_names+=( "offline_uploader_tdus" );   app_codes["offline_uploader_tdus"]="obou"
app_names+=( "oxi_bet" );                 app_codes["oxi_bet"]="oboxibet"
app_names+=( "oxi_misc" );                app_codes["oxi_misc"]="oboximsc"
app_names+=( "oxi_rep" );                 app_codes["oxi_rep"]="obrep"
app_names+=( "oxi_ro" );                  app_codes["oxi_ro"]="oboxiro"
app_names+=( "oxi_secure" );              app_codes["oxi_secure"]="oboxisec"
app_names+=( "perfmon_release_scripts" ); app_codes["perfmon_release_scripts"]="obpm"
app_names+=( "rpt" );                     app_codes["rpt"]="obrpt"
app_names+=( "settlement_engine" );       app_codes["settlement_engine"]="obstl"
app_names+=( "ti2" );                     app_codes["ti2"]="obti"
app_names+=( "trackers" );                app_codes["trackers"]="obtrk"
app_names+=( "xsys" );                    app_codes["xsys"]="obxsq"
app_names+=( "dbServer")                  app_codes["dbServer"]="ixs"
 
 
START_DATETIME=$(date +"%Y-%m-%d_%H-%M-%S")
echo New run started at: $START_DATETIME
 
EXPORT_FILENAME="${BRAND}_apps.csv"
NUMBER_OF_BOXES_TO_CHECK=50

if [[ $BRAND == "PPB" ]]; then
    echo app_name,app_code,bf_qa,bf_nxt,bf_prf,bf_prd,pp_qa,pp_nxt,pp_prf,pp_prd > $EXPORT_FILENAME

    for app_name in ${app_names[@]}; do

        app_code=${app_codes[$app_name]}
        echo -n ${app_name},${app_code} >> $EXPORT_FILENAME

        for brand in bf pp; do
            for env in qa nxt prf prd; do
                
                echo -n checking ${app_code}_${brand}_${env}:
                boxes_found=0

                for i in $(seq 1 $NUMBER_OF_BOXES_TO_CHECK); do

                    if [ "$i" -gt  9 ]; then
                       box=$i
                    else
                       box=\0$i
                    fi

                    ssh_name="ie1-${app_code}${brand}${box}-${env}.${env}.betfair"
                    cmd="ping -w1 $ssh_name"

                    #We don't want the ping error messages to appear so we suppress them with redirecting to /dev/null
                    eval result=\$\("$cmd"\) &> /dev/null
                    result=$(echo $result | awk '{print $1;}')
                    
                    if [[ $result == "PING" ]]; then
                        boxes_found=$((boxes_found+1))
                    else
                        echo $boxes_found boxes found
                        echo -n ,${boxes_found} >> $EXPORT_FILENAME
                        boxes_found=0
                        break;
                    fi
                done
            done
        done
        echo >> $EXPORT_FILENAME
    done
 fi 

if [[ $BRAND == "FD" ]]; then
    echo -n "app_name,app_code,fd_nxt,fd_intbs1,fd_glibs1,fd_dgebs1," > $EXPORT_FILENAME
	echo -n "fd_prdwv,fd_prdva,fd_prdtn,fd_prdpa,fd_prdoh,fd_prdny," >> $EXPORT_FILENAME
	echo -n "fd_prdnv,fd_prdnj,fd_prdms,fd_prdmi,fd_prdma,fd_prdin," >> $EXPORT_FILENAME
	echo    "fd_prdil,fd_prdia,fd_prdct,fd_prdco,fd_prdaz" >> $EXPORT_FILENAME

	envset0="nxt intbs1 glibs1 dgebs1"
	envset1="prdwv prdva prdtn prdpa prdoh prdny"
	envset2="prdnv prdnj prdms prdmi prdma prdin"
	envset3="prdil prdia prdct prdco prdaz"
	allenvironments="${envset0} ${envset1} ${envset2} ${envset3}"

    for app_name in ${app_names[@]}; do

        app_code=${app_codes[$app_name]}

        # There is an incosistency in naming for JMS pusher. On FD app_code is 'jms' instead of 'jmsp'. We check this here.
        if [[ ${app_code} == "objmsp" ]]; then
            app_code=objms
        fi
        
        echo -n ${app_name},${app_code} >> $EXPORT_FILENAME

        for brand in fd; do

            for env in ${allenvironments}; do
 
               echo -n checking ${app_code}_${brand}_${env}:
     
               boxes_found=0
     
                for i in $(seq 1 $NUMBER_OF_BOXES_TO_CHECK); do
                   if [ "$i" -gt  9 ]; then
                       box=$i
                   else
                       box=\0$i
                   fi
     
                   #Check if we have a DEV or PRD environment
                   if [[ ${env} == "dgebs1" ]]; then
                       # DGE env has a different pattern than the other pre prod envs
                       ssh_name="use1-${app_code}${brand}${box}-${env}.dev.fndlsb.net"
                   elif [[ ${env:0:3} != prd ]]; then
                       ssh_name="njss1-${app_code}${brand}${box}-${env}.dev.fndlsb.net"
                   else
                       ssh_name="${env:3}-${app_code}${brand}${box}-${env}.prd.fndlsb.net"
                   fi
                       cmd="ping -w1 $ssh_name"
                       
                   #We don't want the ping error messages to appear so we suppress them with redirecting to /dev/null
                   eval result=\$\("$cmd"\) &> /dev/null
                   result=$(echo $result | awk '{print $1;}')
                    
                   if [[ $result == "PING" ]]; then
                       boxes_found=$((boxes_found+1))
                   else
                       echo $boxes_found boxes found
                       echo -n ,${boxes_found} >> $EXPORT_FILENAME
                       boxes_found=0
                       break;
                   fi
     
               done
            done
        done
        echo >> $EXPORT_FILENAME
    done
fi
 
echo Started at : $START_DATETIME
echo Finished at: $(date +"%Y-%m-%d_%H-%M-%S")
 
echo After checking ${EXPORT_FILENAME}, use it with the alias creation script.
