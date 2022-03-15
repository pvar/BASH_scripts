#!/usr/bin/expect -f
#
# == Prerequisites ==
#
# A) Connect to work VPN
#
# B) Set up passwordless-ssh to londldev02 (or 01 or 03) with ssh-copy-id
#
# C) Create the folders and files as defined in the very first
#    INPUT SECTION of the script and add respective passwords in them
#
# D) In ~/.ssh/config (create if not exists), add the following  
#        and update with your usernames:
#
# # OB Dev servers
# Host lonldev0*
# User                <SET ME:dev01 OB username>
# ServerAliveInterval 60
# ControlPath         ~/.ssh/controlmasters/%r@%h:%p
# ControlMaster       auto
# ControlPersist      1h
#
# Host *.fndlsb.net *.starsops.com
# User                <SET ME:FD LDAP username>
# ServerAliveInterval 60
# ProxyCommand        ssh -q lonldev03 -W %h:%p
# ControlPath         ~/.ssh/controlmasters/%h:%p
# ControlMaster       auto
# ControlPersist      1h

#### INPUT SECTION START
set ppb_user_file           "~/credentials/ppb_user.txt"
set fd_user_file            "~/credentials/fd_user.txt"
set fd_pass_file            "~/credentials/fd_pass.txt"
set logserver_pass_file     "~/credentials/logserver_pass.txt"
set daily_release_pass_file "~/credentials/daily_release_pass.txt"
set fd_grafana_pass_file    "~/credentials/fd_grafana_pass.txt"
set isp_user_file           "~/credentials/isp_user.txt"
set isp_pass_file           "~/credentials/isp_pass.txt"
##### INPUT SECTION END

set timeout -1
match_max 100000


# Set the mapped boxes of daily and release envs across all states
set daily_release_box_nums [dict create  \
				bf_daily_01   "10.183.27.51" \
				bf_daily_02   "10.183.26.16" \
				bf_release_01 "10.183.27.16" \
				bf_release_02 "10.183.27.186" \
				fd_daily_01   "10.183.27.195" \
				fd_daily_02   "10.183.27.163" \
				fd_release_01 "10.183.27.217" \
				fd_release_02 "10.183.27.187"]
# Set the mapped boxes of PPB vasco
set vasco_box_nums [dict create  \
				bf_vasco_01   "10.163.128.38" \
				bf_vasco_02   "10.40.14.246" \
				pp_vasco_01   "10.163.128.38" \
				pp_vasco_02   "10.40.14.246" ]
# Set the mapped boxes of ISP bastions
set isp_bastion_box_nums [dict create  \
				isp_bastion_01 "awssgbastion01.bastion.isp.starsops.com" \
				isp_bastion_02 "awssgbastion02.bastion.isp.starsops.com" \
				isp_bastion_03 "awssgbastion03.bastion.isp.starsops.com"]

# Set the grafana co-hosted states
# also needed for building up the target box name
set grafana_main_state [dict create  \
				"preprod" "" \
				"wv" "" \
				"co" "" \
				"in" "in" \
				"il" "in" \
				"tn" "tn" \
				"mi" "tn" \
				"pa" "pa" \
				"nj" "pa" \
				"ia" "ia" \
				"ia" "ia" \
				"ct" "ct" \
				"az" "ct" \
				"la" "la" \
				"wy" "la" \
				"md" "md" \
				"ny" "md"]

# Get the input variables
lassign $argv state app boxno dbtype

# If help is needed or wrong variables are given to input then print usages and exit
if {[string first "help" $state] != -1 || $app eq "" || [lsearch -exact [list {} pri hdr] $dbtype] < 0} {
	set script_name [file tail $argv0]
	puts stderr "************************************************************************************"
	puts stderr "Usage: $script_name state app ?boxno? dbtype?"
	puts stderr "    State : Its FD | BF | ISP | <specific state> | int | nxt | gli | dge | prf"
	puts stderr "    App   : Potential values "
	puts stderr "            - TLA name - If unsure, look in following wiki for app_codes in discover_boxes.sh script and remove the 'ob' from it"
	puts stderr "            https://wiki.sgdigital.com/pages/viewpage.action?spaceKey=BTF&title=Automated+aliases+for+i2+environment"
	puts stderr "            - daily for the daily env"
	puts stderr "            - release for the release env"
	puts stderr "            - logs for the logs server"
	puts stderr "            - db for the db server"
	puts stderr "            - mon for the monitoring box"
	puts stderr "    Boxno : Its the box number of the app. Will be ignored when app is 'logs'"
	puts stderr "    dbtype : Defaults to hdr. Acceptable values are 'pri' and 'hdr'"
	puts stderr "************************************************************************************"
	puts stderr "    Examples :"
	puts stderr "       BF        Daily   box2      : $script_name bf daily 2"
	puts stderr "       FD        Release box1      : $script_name fd release 1"
	puts stderr "       BF        vasco   box2      : $script_name bf vasco 2"
	puts stderr "       PP        vasco   box1      : $script_name pp vasco 1"
	puts stderr "       ISP       bastion box1      : $script_name isp bastion 1"
	puts stderr "       FD TN     logs              : $script_name tn logs"
	puts stderr "       FD TN     stl     box2      : $script_name tn stl 2"
	puts stderr "       FD TN     DB      box2  hdr : $script_name tn db 2"
	puts stderr "       FD TN     DB      box2  pri : $script_name tn db 2 pri"
	puts stderr "       FD TN     Monitor box1      : $script_name tn mon 1"
	puts stderr "       FD nxt    dbpub   box2      : $script_name nxt pub 2"
	puts stderr "       FD nxt    dbpub   box2      : $script_name nxt pub 2"
	puts stderr "       FD nxt    logs              : $script_name nxt logs"
	puts stderr "       FD intbs1 xsq     box1      : $script_name int xsq 1"
	puts stderr "       FD intbs1 xsq     box1      : $script_name intbs1 xsq 1"
	puts stderr "       FD intbs1 logs              : $script_name int logs"
	puts stderr "       FD glibs1 xsqlo   box1      : $script_name glibs1 xsqlo 1"
	puts stderr "       FD glibs1 xsqlo   box1      : $script_name gli xsqlo 1"
	puts stderr "       FD glibs1 logs              : $script_name gli logs"
	puts stderr "       FD dgebs1 admin   box1      : $script_name dgebs1 adm 1"
	puts stderr "       FD dgebs1 admin   box1      : $script_name dge adm 1"
	puts stderr "       FD dgebs1 logs              : $script_name dge logs"
	puts stderr "       FD prfbs  xsq     box1      : $script_name prf xsq 1"
	puts stderr "       FD prfbs  xsq     box1      : $script_name prfbs xsq 1"
	puts stderr "       FD prfbs  logs              : $script_name prfbs logs"
	puts stderr "       FD PA     grafana           : $script_name pa grf"
	puts stderr "       FD PA     grafana           : $script_name pa grafana"
	puts stderr "       FD WV     grafana           : $script_name wv grf"
	puts stderr "       FD preprd grafana           : $script_name preprod grf"
	puts stderr "************************************************************************************"
	exit 1
}

# Allow shorter names
if {$state eq "dge" || $state eq "int" || $state eq "gli"} {
	set state    "${state}bs1"
} elseif {$state eq "prf"} {
	set state    "${state}bs"
}

if {$app eq "grf"} {
	set app    "grafana"
}

# Default to box 1 if nothing provided
if {$boxno eq ""} {
	set boxno 1
}
# Convert the box number to 2 digits
set boxno [format "%02d" $boxno]

# Default to hdr DB if nothing is provided
if {$dbtype eq ""} {
	set dbtype "hdr"
}

# Handle the case of nonprod FD log servers (each one has individual log server now)
if {$app eq "logs" && [lsearch -exact [list nxt intbs1 glibs1 dgebs1 prfbs] $state] > -1} {
	set app "klc"
}

# Read pwd files
set f [open $ppb_user_file];           lassign [split [read $f] "\n"] ppb_user;           close $f;
set f [open $fd_user_file];            lassign [split [read $f] "\n"] fd_user;            close $f;
set f [open $fd_pass_file];            lassign [split [read $f] "\n"] fd_pass;            close $f;
set f [open $logserver_pass_file];     lassign [split [read $f] "\n"] logserver_pass;     close $f;
set f [open $daily_release_pass_file]; lassign [split [read $f] "\n"] daily_release_pass; close $f;
set f [open $fd_grafana_pass_file];    lassign [split [read $f] "\n"] fd_grafana_pass;    close $f;
set f [open $isp_user_file];           lassign [split [read $f] "\n"] isp_user;          close $f;
set f [open $isp_pass_file];           lassign [split [read $f] "\n"] isp_pass;          close $f;

# Default the box username/password and brand to fd and, if needed, will be overriden later
set brand    "fd"
set username ${fd_user}
set password ${fd_pass}

# Set the variables that will construct the box name
switch -nocase $state {
	"nxt" -
	"intbs1" -
	"glibs1" {
		set prefix       "njss1"
		set state_prefix "-"
		set env_type     "dev"
	}
	"dgebs1" -
	"prfbs" {
		set prefix       "use1"
		set state_prefix "-"
		set env_type     "dev"
	}
	default {
		set prefix $state
		set state_prefix "-prd"
		set env_type     "prd"
	}
}

switch -nocase $app {
	"db" {
		set appstr   "ixs"
	}
	"mon" {
		set appstr $app
	}
	"logs" {
		# For non prod logs the app is not "logs" anymore. Its klc so it matches the default case
		set prefix       "ob"
		set state_prefix ""
		set env_type     "public"

		set appstr "rsyslog"
		set brand  ""
		set boxno  ""
		set state  ""

		set username "openbet"
		set password ${logserver_pass}
	}
	"grafana" {
		set prefix       "ob"
		if {$state eq "wv" || $state eq "co"} {
			set state_prefix "-prod"
		} elseif {$state eq "preprod"} {
			set state_prefix ""
		} else {
			set state_prefix "-prd"
		}
		if {$state eq "wv" || $state eq "co" || $state eq "preprod"} {
			set env_type "public"
		} else {
			set env_type     "mgmt"
		}

		set appstr "perfmon"
		set brand  ""
		set boxno  ""
		# We set the state to be the main one (as multiple states are hosted by a single grafana instance)
		set state [dict get $grafana_main_state "${state}"]

		set username "devadmin"
		set password $fd_grafana_pass
	}
	"daily" -
	"release" {
		set username "openbet"
		set password ${daily_release_pass}
	}
	"vasco" {
		set username "${ppb_user}"
	}
	"bastion" {
		set username ${isp_user}
		set password ${isp_pass}
	}
	default {
		set appstr "ob$app"
	}
}

# Choose the configured box if we need daily or release envs or else build up the box name
switch -nocase $app {
	"daily" -
	"release" {
		set target [dict get $daily_release_box_nums "${state}_${app}_${boxno}"]
	}
	"vasco" {
		set target [dict get $vasco_box_nums "${state}_${app}_${boxno}"]
	}
	"bastion" {
		set target [dict get $isp_bastion_box_nums "${state}_${app}_${boxno}"]
	}
	default {
		set target ${prefix}-${appstr}${brand}${boxno}${state_prefix}${state}.${env_type}.fndlsb.net
	}
}

# Attempt to ssh
spawn ssh -o StrictHostKeyChecking=no $username@$target

# Will determine whether we need to change to openbet user or not
set su_openbet         0
# If it is a log server box, change directory to the log folders
set cd_central_logging 0
set isp_duo_prompt 0
expect {
	"Are you sure you want to continue connecting (yes/no)? " {
		send -- "yes\n"
		exp_continue
	}
	"${username}@* password: " {
		# for vasco boxes let the user put the password
		if {$app ne "vasco"} {
			send -- $password
			send -- "\n"
			exp_continue
		}
	}
	"Password: " {
		# for ISP bastion we could send some dummy passcode first and use option #1 to get the prompt in DUO mobile app
		if {$app eq "bastion"} {
			if {$isp_duo_prompt ne 0} {
				send -- "1234\n"
			} else {
				send -- $password
				send -- "\n"
			}
			exp_continue
		}
	}
	"Passcode or option (1-1): " {
		if {$app eq "bastion"} {
			send -- "1\n"
			set isp_duo_prompt 1
			exp_continue
		}
	}
	"Permission denied, please try again." {
		interact
		exit 0
	}
	"\$ " { 
			if {$app ne "logs" && $app ne "daily" && $app ne "release" && $app ne "grafana" && $app ne "bastion"} { set su_openbet 1}
			if {$app eq "logs" || $app eq "klc"} { set cd_central_logging 1}
	}
	"> " {}
}

if {$app eq "db"} {
	send -- "onstat -\n"
	send -- "echo 'Connecting to $dbtype database'"
	send -- "\n"
	send -- "rm -f ~/.dbacc.sql\n"
	send -- "echo \"connect to 'openbet@g_$dbtype' user 'openbet' using 'openbet'; set isolation dirty read;\" > .dbacc.sql"
	send -- "\n"
	send -- "chmod 400 ~/.dbacc.sql\n"
	send -- "dbaccess - ~/.dbacc.sql -\n"
} elseif {$su_openbet} {
	send -- "sudo -iu openbet\n"
	expect {
		"password for " {
			send -- $fd_pass
			send -- "\n"
			exp_continue
		}
		"\$ " {}
	}
}

if {$cd_central_logging} {
	send -- "cd /central-logging/logs\n"
	send -- "ls -l\n"
}

interact
