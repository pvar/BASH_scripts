#!/bin/bash

echo -e 'This script will create the alises for the PPB/FD environments\n'

for brand in PPB FD
do
    echo -e "\nPlease enter your $brand username or leave empty to skip this brand"
    read -p "Your $brand username: " ${brand}_USER
done

echo ""

# PPB 
if [[ $PPB_USER != "" ]]; then
    BRAND="PPB"
    CSV_FILE="${BRAND}_apps.csv"
    echo -e "\n ~~~ $BRAND ~~~"
    echo "Checking for $CSV_FILE in the current folder..." 
    if [ ! -f $CSV_FILE ]; then
        echo -e "The csv file '$CSV_FILE', containing the application info was not found! Skipping environment.\n"
    else
        TARGET_FILENAME="${BRAND}_aliases"
        echo "Creating $TARGET_FILENAME."
        >$TARGET_FILENAME

        # Read csv file and create arrays dynamicaly
        while IFS=, read -r app_name app_code bf_qa bf_nxt bf_prf bf_prd pp_qa pp_nxt pp_prf pp_prd
        do
            # Bypass the header or a blank line
            if [[ $app_name == "app_name" || $app_name == "" ]]; then
                continue
            fi
        
            for brand in bf pp; do
                echo -e "\n# $brand $app_name aliases" >> $TARGET_FILENAME
                for env in qa nxt prf prd; do
                    box_name=${brand}_${env}
                    nr_of_boxes=${!box_name}

                    for i in $(seq 1 $nr_of_boxes); do
                        if [ "$i" -gt  9 ]; then
                            box=$i
                        else
                            box=\0$i
                        fi

                        for dc in ie1 ie2; do
                            alias_name=${brand}_${env}_${app_name}_${dc}_${box}
                            ssh_name="${dc}-${app_code}${brand}${box}-${env}.${env}.betfair"

                            # For the DB servers we add the onstat command to know if we landed on primary or rss (read-only) DB
                            if [[ ${app_name} == "dbServer" ]]; then
                                echo "alias ${alias_name}='ssh -o \"StrictHostKeyChecking=no\" -o \"UserKnownHostsFile=/dev/null\" ${PPB_USER}@${ssh_name} -t '\''onstat -; bash -l'\'''" >> $TARGET_FILENAME
                            else
                                echo "alias ${alias_name}='ssh -o \"StrictHostKeyChecking=no\" -o \"UserKnownHostsFile=/dev/null\" ${PPB_USER}@${ssh_name} -t '\''sudo -iu openbet'\'''" >> $TARGET_FILENAME
                            fi 
                        done
                    done
                done
            done
        done < $CSV_FILE
    echo -e "\nYou can copy the aliases created by running\ncat $TARGET_FILENAME | xclip\nand using the middle mouse click to paste."
    fi
fi

#FD
if [[ $FD_USER != "" ]]; then
    BRAND="FD"
    CSV_FILE="${BRAND}_apps.csv"
    echo -e "\n ~~~ $BRAND ~~~"
    echo "Checking for $CSV_FILE in the current folder..." 
    if [ ! -f $CSV_FILE ]; then
       echo -e "The csv file '$CSV_FILE', containing the application info was not found! Skipping environment.\n"
    else
        TARGET_FILENAME="${BRAND}_aliases"
        echo "Creating $TARGET_FILENAME."
        > $TARGET_FILENAME
    
        # Read csv file and create arrays dynamicaly
        while IFS=, read -r app_name app_code fd_nxt fd_intbs1 fd_glibs1 fd_dgebs1 fd_prdwv fd_prdco fd_prdil fd_prdin fd_prdpa fd_prdnj
        do
            # Bypass the header or a blank line
            if [[ $app_name == "app_name" || $app_name == "" ]]; then
                continue
            fi
    
            for brand in fd; do
                echo -e "\n# $brand $app_name aliases" >> $TARGET_FILENAME
        
                for env in nxt intbs1 glibs1 dgebs1 prdwv prdco prdil prdin prdpa prdnj; do
                    box_name=${brand}_${env}
                    nr_of_boxes=${!box_name}
    
                    for i in $(seq 1 $nr_of_boxes); do
                        if [ "$i" -gt  9 ]; then
                            box=$i
                        else
                            box=\0$i
                        fi
    
                        # There is an incosistency in naming for JMS pusher. On FD app_code is 'jms' instead of 'jmsp'. We check this here.
                        if [[ ${app_code} == "objmsp" ]]; then
                            app_code=objms
                        fi
    
                        for dc in njss1; do
                            alias_name=${brand}_${env}_${app_name}_${dc}_${box}
                            
                            #Check if we have a DEV or DGE or PRD environment
                            if [[ $env == "dgebs1" ]]; then
                                # DGE env has a different pattern than the other pre prod envs
                                ssh_name="use1-${app_code}${brand}${box}-${env}.dev.fndlsb.net"
                            elif [[ ${env:0:3} != prd ]]; then
                                ssh_name="${dc}-${app_code}${brand}${box}-${env}.dev.fndlsb.net"
                            else
                                ssh_name="${env:3}-${app_code}${brand}${box}-${env}.prd.fndlsb.net"
                            fi

                            # For the DB servers we add the onstat command to know if we landed on primary or rss (read-only) DB
                            if [[ ${app_name} == "dbServer" ]]; then
                                echo "alias ${alias_name}='ssh -o \"StrictHostKeyChecking=no\" -o \"UserKnownHostsFile=/dev/null\" ${FD_USER}@${ssh_name} -t '\''onstat -; bash -l'\'''" >> $TARGET_FILENAME
                            else
                                echo "alias ${alias_name}='ssh -o \"StrictHostKeyChecking=no\" -o \"UserKnownHostsFile=/dev/null\" ${FD_USER}@${ssh_name} -t '\''sudo -iu openbet'\'''" >> $TARGET_FILENAME
                            fi
                        done
                    done
                done
            done
        done < $CSV_FILE
    echo -e "\nYou can copy the aliases created by running\ncat $TARGET_FILENAME | xclip\nand using the middle mouse click to paste."
    fi
fi