dl () {
	# check number of parameters (arguments actually)
	if [[ $# -eq 0 ]]; then
		echo "No application specified!"
		echo "Usage: ${FUNCNAME[0]} app_name [fitlering term]..."
		return
	fi

	local cmd="dc_go;docker-compose logs -f --tail 32 ${1}-app"

	# check if any filtering terms were supplied
	if [[ $# -gt 1 ]]; then
		# get terms (all parameters but first)
		local params=$*
		local params=${params#* }

		# add filtering terms
		for param in $params; do
			local filter=" | grep ${param}"
			local cmd+=$filter
		done
	fi

	# handle INT signal (CTLR-C)
	# continue after the interrupted command
	trap 'exit 1;' INT

	# execute command
	eval $cmd

	# go back...
	cd -
}

_dl_completions()
{
	CONTAINERS=$(docker ps --format "{{.Names}}" | awk '{print $1}' | awk -F "dev_" '{print $2}' | sed -r 's/_[1..9]//g' | sed -r 's/-[a-z]+//g' | uniq)
	COMPREPLY=($(compgen -W "$CONTAINERS" "${COMP_WORDS[1]}"))
}
complete -F _dl_completions dl
