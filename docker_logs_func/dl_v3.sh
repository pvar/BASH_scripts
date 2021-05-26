dl () {
	# check number of parameters (arguments actually)
	if [[ $# -eq 0 ]]; then
		echo "No application specified!"
		echo "Usage: ${FUNCNAME[0]} app_name [fitlering term]..."
		return
	fi

	local cmd="dc_go;docker-compose logs -f --tail 32 ${1}-app"

	# drop first parameter
	# shift the rest in place ($N+1->$N)
	shift

	# add filtering terms
	for param in $*; do
		local filter=" | grep ${param}"
		local cmd+=$filter
	done

	# execute command in separate process
	# NOTE: When CTRL-C is pressed, the child-process exits
    # and the user regains control of his/her shell, in which
	# the current directory never changed :)
	eval "( $cmd )"
}

_dl_completions()
{
	CONTAINERS=$(docker ps --format "{{.Names}}" | awk '{print $1}' | awk -F "dev_" '{print $2}' | sed -r 's/_[1..9]//g' | sed -r 's/-[a-z]+//g' | uniq)
	COMPREPLY=($(compgen -W "$CONTAINERS" "${COMP_WORDS[1]}"))
}
complete -F _dl_completions dl
