#!/usr/bin/env bash
##
## `mpd-configure' is a bash script that tries to ease the
## configuration of mpd for audiophile purposes.
##
##  Copyright (C) 2015 Ronald van Engelen <ronalde+gitlab@lacocina.nl>
##  This program is free software: you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation, either version 3 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program.  If not, see <http://www.gnu.org/licenses/>.
##
## The script, helpers and documentation are published at 
## https://gitlab.com/ronalde/mpd-configure
## 
## Also see `README'

LANG=C
APP_NAME_MPDCONFIGURE="mpd-configure"
APP_URL="https://gitlab.com/ronalde/mpd-configure/"
APP_VERSION_MPDCONFIGURE="0.9.9"

### defaults
## default network address to listen to
CONF_MPD_NETWORK_ADRESS_DEFAULT="0.0.0.0"
## default network port to listen on
CONF_MPD_NETWORK_PORT_DEFAULT="6600"
## default maximum number of files in music directory
MAX_PLAYLIST_LENGTH_DEFAULT="16384"

function die_configure() {
    printf "\nError in %s (v%s):\n%s\n" \
	   "${APP_NAME_MPDCONFIGURE}" "${APP_VERSION_MPDCONFIGURE}" "$@" 1>&2;
    exit 1
}

function debug_configure() {
    printf "DEBUG %s *** %s.\n"  "${APP_NAME_MPDCONFIGURE}" "$@" 1>&2;
}

function debug_function() {
    printf "DEBUG %-18s:\n" "${APP_NAME_MPDCONFIGURE}" 1>&2;
    printf "\tentering function \`%s',\n" "$1" 1>&2;
    printf "\twith arguments \`%s'.\n" "$2" 1>&2;
}


function really_write() {
    ## writes the contents of CONF_CONTENTS to the file specified in $1.
    ## returns success or error with descriptive string
    [[ ! -z "${DEBUG}" ]] && debug_function "${FUNCNAME[0]}" "$*"

    mpd_conffile="$1"
    ## do the actual writing
    #debug_configure "${CONF_CONTENTS}"
    res="$(echo -e "${CONF_CONTENTS}" > "${mpd_conffile}")"
    if [[ $? -ne 0 ]]; then
	## return an error with descriptive message
	printf "Could not write to \`%s'" "${mpd_conffile}"
	return 1
    else
	## return the result
	printf "${mpd_conffile}"
    fi
}

function check_or_create_targetdir() {
    ## checks if the parent directory for target mpd configuration $1
    ## exists and is writable, otherwise attempts to create
    ## it.
    ## returns success or an error with descriptive string.
    [[ ! -z "${DEBUG}" ]] && debug_function "${FUNCNAME[0]}" "$*"

    mpd_conf_file="$1"
    mpd_conf_dir="$(dirname "${mpd_conf_file}")"
    errors=()
    
    if [[ ! -d "${mpd_conf_dir}" ]]; then
	[[ ! -z ${DEBUG} ]] && \
	    debug_configure "${FUNCNAME[0]}: conf dir \`${mpd_conf_dir}' does not exist, \
try to create it"
	res="$(mkdir -p "${mpd_conf_dir}" 2>&1)"
	if [[ $? -ne 0 ]]; then
	    [[ ! -z ${DEBUG} ]] && \
		debug_configure "${FUNCNAME[0]}: error creating mpd_conf_dir \
 \`${mpd_conf_dir}': \`${err}'"
	    printf " %s can't create parent directory \`%s'.\n" \
		   "-" "${mpd_conf_dir}"
	    return 1
	else
	    [[ ! -z ${DEBUG} ]] && \
		debug_configure "${FUNCNAME[0]}: successfully created \
mpd_conf_dir \`${mpd_conf_dir}'"
	    printf "%s" "${mpd_conf_dir}"
	fi
    else
	[[ ! -z ${DEBUG} ]] && \
		debug_configure "${FUNCNAME[0]}: mpd_conf_dir \`${mpd_conf_dir}' already exists"
	## conf dir exists, check if it writable
	if [[ ! -w "${mpd_conf_dir}" ]]; then
	    [[ ! -z ${DEBUG} ]] && \
		debug_configure "${FUNCNAME[0]}: mpd_conf_dir \`${mpd_conf_dir}' already exists"
	    printf " - no write permission in target directory \`%s'." "${mpd_conf_dir}"
	    return 1
	else
	    [[ ! -z ${DEBUG} ]] && \
		debug_configure "${FUNCNAME[0]}: conf dir \`${mpd_conf_dir}' is writable"
	    printf "%s" "${mpd_conf_dir}"
	fi
    fi
}

function check_existing_conffile() {
    ## checks if target mpd configuration file $1 exists and is
    ## writable.
    ## returns success or an error with descriptive string.
    mpd_conf_file="$1"
    if [[ -f "${mpd_conf_file}" ]]; then
	if  [[ ! -w "${mpd_conf_file}" ]]; then
	    ## not writable, exit with error 
	    printf " %s existing file \`%s' is present, but is not writable,\n" \
		   "-" "${mpd_conf_file}"
	    return 1
	else
	    [[ ! -z ${DEBUG} ]] && \
		debug_configure "conffile \`${mpd_conf_file}' exists and is writable"
	    ## return the path to indicate it does exits and is writable
	    printf "%s" "${mpd_conf_file}"
	fi
    else
	[[ ! -z ${DEBUG} ]] && \
	    debug_configure "conffile \`${mpd_conf_file}' does not exist"
	## return success (but no path)
	return 0
    fi
}

function make_temp_conf() {
    ## makes a temporary file for storing the mpd configuration file.
    ## returns the path to the created file or error.
    [[ ! -z "${DEBUG}" ]] && debug_function "${FUNCNAME[0]}" "$*"

    ## try to make a temp file in /tmp 
    tempfile="$(mktemp /tmp/${APP_NAME_MPDCONFIGURE}.XXXX.conf)"
    if [[ $? -ne 0 ]]; then
	[[ ! -z ${DEBUG} ]] && \
	    debug_configure "Unable to create a temporary file \`${tempfile}'"
	printf "  %s unable to create a temporary file \`%s'\n" \
	       "-" "${tempfile}" 1>&2;
	# TODO: print to std_out
	die "Unable to create a temporary file \`${tempfile}'"
    else
	[[ ! -z ${DEBUG} ]] && \
	    debug_configure "temporary file \`${tempfile}' created"
	printf "   will store the generated file in a temporary file instead.\n" 1>&2;
	## set a new target path 
	mpd_conf_file="${tempfile}"
	printf "%s" "${mpd_conf_file}"
    fi
}

function backup_original_conf() {
    ## create a backup of the current config file $1
    [[ ! -z "${DEBUG}" ]] && debug_function "${FUNCNAME[0]}" "$*"
    
    mpd_conf_file="$1"

    if [[ ! -z ${TEMP_CONF_BACKUP} ]]; then
	if [[ -f "${TEMP_CONF_BACKUP}" ]]; then
	    printf "TEMP_CONF_BACKUP specified to \`%s' but already exists; not overwriting." \
		   "${TEMP_CONF_BACKUP}"
	    return 1
	fi
    else 
	TEMP_CONF_BACKUP="$(mktemp -p /tmp ${mpd_conf_file##*/}.XXXX)"
	if [[ $? -ne 0 ]]; then
	    printf "error creating a temporary file which should hold the backup."
	    return 1
	else
	    [[ ! -z ${DEBUG} ]] && \
		debug_configure "will create backup in \`${TEMP_CONF_BACKUP}'."
	fi
    fi
    res="$(cp -av "${mpd_conf_file}" "${TEMP_CONF_BACKUP}")"
    if [[ $? -ne 0 ]]; then
	## error creating a backup with copy
	printf "${res}"
	return 1
    else	    
	printf "%s" "${TEMP_CONF_BACKUP}"
    fi
    
    
}



function write_conffile() {
    ## prepares to write to the target mpd configuration file specified by $1.
    ## returns success or an error with descriptive string.
    [[ ! -z "${DEBUG}" ]] && debug_function "${FUNCNAME[0]}" "$*"

    declare -a errors
    error_message=""
    mpd_conf_file="$1"
    existing_file=
    mpd_confdir=""
    maketemp=
    existing_file="$(check_existing_conffile "${mpd_conf_file}")"
    ## check if the file exists
    if [[ $? -ne 0 ]]; then
	## the file exists but is not writable
	maketemp="${existing_file}"
    else
	if [[ -z "${existing_file}" ]]; then
	    ## new file, check the (parent) path
	    target_dir_writable="$(check_or_create_targetdir "${mpd_conf_file}")"
	    if [[ $? -ne 0 ]]; then 
		maketemp="${target_dir_writable}"
	    fi
	fi
    fi

    if [[ ! -z ${maketemp} ]]; then
	## either existing file or new target directory is not writable
	[[ ! -z ${DEBUG} ]] && \
	    debug_configure "can't write to target file \`${mpd_conf_file}': \`${maketemp}'"
	printf "\nError: unable to write to %s \`%s':\n" \
	       "${MSG_MPD_CONFFILE}" "${mpd_conf_file}" 1>&2;
	printf "%s\n" "${maketemp}" 1>&2;
	mpd_conf_file="$(make_temp_conf)"
    else 
	## only prompt when both OVERWRITE_EXISTING_CONFFILE and
	## DISABLE_PROMPTS are not set
	if [[ ! -z ${existing_file} ]]; then
	    if [[ -z ${OPT_QUIET} ]]; then 
		printf " %s existing %s found in \`%s',\n" \
		       "-" "${MSG_MPD_CONFFILE}" "${mpd_conf_file}" 1>&2;
	    fi
	    ## check if a prompt is needed
	    if [[ ! -z ${SKIP_BACKUP} ]] || [[ ! -z ${DISABLE_PROMPTS} ]]; then
		## prompt not needed
		if [[ -z ${OPT_QUIET} ]]; then 
		    printf "     but user requested overwriting of original conf file\n" 1>&2;
		    printf "     by setting either SKIP_BACKUP or DISABLE_PROMPTS.\n" 1>&2;
		fi
		overwrite="yes"
	    else
		## prompt needed
		prompt="     overwrite it (while making a backup of the original)?: "
		overwrite="$(read -e -p "${prompt}" -i "Yes" \
overwrite && echo -e "${overwrite}")"
	    fi
	    ## if settings or prompt returns (downcased) `yes' then overwrite the file
	    if ! [[ "${overwrite,,}" =~ yes ]]; then
		## user chose no to overwrite; try to save in temporary file, otherwise
		## exit with message
		printf "\nNot overwriting existing %s \`%s'.\n" \
		       "${MSG_MPD_CONFFILE}" "${mpd_conf_file}" 1>&2;
		mpd_conf_file="$(make_temp_conf)"
	    else
		## original file needs to be overwritten, check if a backup is needed
		if [[ ! -z ${SKIP_BACKUP} ]]; then
		    if  [[ -z ${OPT_QUIET} ]]; then 
			printf "  %s will overwrite existing conffile without making a backup,\n" 1>&2;
			printf "     as requested by the user by setting SKIP_BACKUP.\n" 1>&2;
		    fi
		else
		    ## backup is needed
		    temp_backup_file="$(backup_original_conf "${mpd_conf_file}")"
		    if [[ $? -ne 0 ]]; then
			printf "could not create backup of \`%s' (%s).\n" \
			       "${mpd_conf_file}" "${temp_backup_file}" 1>&2;
			printf "will print config to stdout instead.\n" 1>&2;
			return 1
		    else
			printf " %s backup of existing %s created in \`%s'\n" \
			       "-" "${MSG_MPD_CONFFILE}" "${temp_backup_file}" 1>&2;
		    fi
		    
		fi
	    fi
	fi
    fi
    ## do the actual writing
    fileok="$(really_write "${mpd_conf_file}")"
    if [[ $? -ne 0 ]]; then
	die "unspecified error"
    else
	printf " %s mpd-configure succesfully created a %s in:\n" \
	       "-" "${MSG_MPD_CONFFILE}" 1>&2;
	## return the resulting file to the calling function
	printf "%s" "${mpd_conf_file}"
    fi

}


function command_not_found() {
    ## give installation instructions when a command is not available
    ## and exit with error,
    [[ ! -z "${DEBUG}" ]] && debug_function "${FUNCNAME[0]}" "$*"

    command="$1"
    package="$2"
    instructions="$3"
    msg="Error: command \`${command}' not found. "

    [[ -z "${instructions}" ]] && \
	msg+="Users of Debian (or deratives, like Ubuntu) can install it with: \
\n sudo apt-get install ${package}" || \
	msg+="${instructions}"

    die_configure "${msg}"

}

function prompt_select_hwaddress() {
    ## display instructions for multiple interfaces and prompt the
    ## user to enter one of the found hwardware addresses, with that
    ## of the first available interface filled in.
    ## returns the index number of the item entered in the array or an
    ## error with description.
    [[ ! -z "${DEBUG}" ]] && debug_function "${FUNCNAME[0]}" "$*"

    selected_address=0
    selected_key=
    prompt_messages+=("Multiple interfaces found:")
    default_aif_hwaddress="${ALSA_AIF_HWADDRESSES[0]}"
    prompt_messages+=("   specify the hardware address of the interface you wish to use")
    prompt_messages+=("   for mpd and press [ENTER] to confirm: ")
    ## format the message
    prompt="$(printf "  %s\n" "${prompt_messages[@]}")"
    ## prompt the user and store the input in alsa_aif_hwaddress
    alsa_aif_hwaddress="$(read -e -p "${prompt}" \
-i "${default_aif_hwaddress}" alsa_aif_hwaddress && \
echo -e "${alsa_aif_hwaddress}")"
    [[ ! -z ${DEBUG} ]] && \
	debug_configure "${FUNCNAME[0]}: user entered \`${alsa_aif_hwaddress}'."
    ## look up the chosen hardware address in the proper array
    for key in "${!ALSA_AIF_HWADDRESSES[@]}"; do
	## set the user selected key and exit loop
	if [[ "${ALSA_AIF_HWADDRESSES[$key]}" = \
					      "${alsa_aif_hwaddress}" ]]; then
	    let selected_key=${key}
	    break
	fi
    done
    
    ## handle empty or invalid input
    msg=""
    if [[ "${ALSA_AIF_HWADDRESSES[$selected_key]}" \
	      != "${alsa_aif_hwaddress}" ]]; then
	prompt_messages=("  NOTE:")			
	if [[ -z ${alsa_aif_hwaddress} ]]; then
	    [[ ! -z ${DEBUG} ]] && \
		debug_configure "${FUNCNAME[0]}: no hwaddress entered"
	    msg="no hardware address "
	else
	    [[ ! -z ${DEBUG} ]] && \
		debug_configure "${FUNCNAME[0]}: an invalid hwaddress \`${alsa_aif_hwaddress}' entered"
	    msg="an invalid hardware address (${alsa_aif_hwaddress})"
	fi
	## return the problem and error code
	printf "  %s %s was entered." "-" "${msg}"
	return 1
    else
	## a valid addres was entered; return its index number
	[[ ! -z ${DEBUG} ]] && \
	    debug_configure "${FUNCNAME[0]}: chosen key \`${selected_key}' for \
interface \`${selected_address}'"

	printf "%s" "${selected_key}"
    fi
}

function select_interface_index() {
    ## select and the hardware address of one of the number of
    ## interfaces found ($1) and return its index number in the
    ## ALSA_AIF_HWADDRESSES array. if one interface is found, use its
    ## index. In case of multiple interfaces show a list of all
    ## interfaces and prompt the user to enter one of them, unless
    ## DISABLE_PROMPTS is set, which defaults to the hardware address
    ## of the first interface found.
    ## returns the index of the chosen hardware address or an error
    ## with description.
    [[ ! -z "${DEBUG}" ]] && debug_function "${FUNCNAME[0]}" "$*"

    interface_count="$1"
    ## variable to hold the index number for the ALSA_AIF_HWADDRESSES
    ## array holding the chosen hardware address
    selected_array_index=0

    case ${interface_count} in
	0)
	    printf "0 interfaces found (THIS SHOULD NOT HAPPEN)"
	    return 1
	    ;;
	1)
	    ## single interface found; use it
	    selected_array_index=0
	    ;;
	*)
	    ## multiple interfaces found
	    if [[ ! -z "${DISABLE_PROMPTS}" ]]; then
		## return the address of the first interface
		## found and inform the user of the decision
		printf " %s multiple interfaces found, \
but user set DISABLE_PROMPTS,\n" \
		       "-" 1>&2;
		printf "     therefore using the first \
one found (${ALSA_AIF_HWADDRESSES[0]}).\n" \
		       "-" 1>&2;
		selected_array_index=0
	    else
		## prompt the user
		selected_array_index="$(prompt_select_hwaddress)"
		if [[ $? -ne 0 ]]; then
		    ## inform the calling function about the error
		    printf "%s" "${selected_array_index}"
		    return 1
		fi
	    fi
    	    ;;
    esac
    
    ## return the selected address to the calling function
    printf "%s" "${selected_array_index}"
}

function fetch_alsa_hwaddresses() {
    ## use alsa-capabilities script to get alsa output interfaces,
    ## thereby filling the approriate global arrays.
    ## returns success or an error.
    [[ ! -z "${DEBUG}" ]] && debug_function "${FUNCNAME[0]}" "$*"
    
    ## when more than one matching output device is found and
    ## DISABLE_PROMPTS is not set, prompt the user to select one,
    ## otherwise use the first device found.
    prompt_messages=()
    selected_array_index=0
    
    ## call return_alsa_interface from the sourced alsa-capabilities
    ## for filling up the array ALSA_AIF_HWADDRESSES
    
    return_alsa_interface 1>&2;
    if [[ $? -ne 0 ]]; then
	## something went wrong in return_alsa_interface
	printf "error in return_alsa_interface." 1>&2;
	return 1
    else
	interface_count="${#ALSA_AIF_HWADDRESSES[@]}"
	[[ ! -z ${DEBUG} ]] && \
	    debug_configure "${FUNCNAME[0]}:  \
audio interfaces after filtering: \`${interface_count}'."
    fi
    return 0
}


function check_readable_path() {
    ## checks if path ($1), needed for ($2) is readable, or adds
    ## problem description ($2) to problems array.
    [[ ! -z "${DEBUG}" ]] && debug_function "${FUNCNAME[0]}" "$*"

    path="$1"
    purpose="$2"
    problem="$3"

    msg="\n  - can't access or read ${purpose} \`${path}',\
\n   you won't be able to ${problem}.\n"
    if [[ ! -d "${path}" ]]; then
	if [[ ! -f "${path}" ]]; then
	    [[ ! -z ${DEBUG} ]] && \
		debug_configure "${FUNCNAME[0]} (line ${LINENO}): $(printf "${msg}")"		
	    PROBLEMS+=("${msg}")
	    return 1
	fi
    fi
}


function check_writeable_path() {
    ## checks if path ($1), needed for ($2) is writeable, or adds
    ## problem description ($2) to problems array.
    [[ ! -z "${DEBUG}" ]] && debug_function "${FUNCNAME[0]}" "$*"

    path="$1"
    purpose="$2"
    problem="$3"

    msg="\n  - can't write to ${purpose} \`${path}',\
\n   you won't be able to ${problem}.\n"

    if [[ ! -w "${path}" ]]; then
	[[ ! -z ${DEBUG} ]] && \
	    debug_configure "${FUNCNAME[0]} (line ${LINENO}): $(printf "${msg}")"
	PROBLEMS+=("${msg}")
	return 1
    fi
}

function parse_configuration_line() {
    ## parse a line from mpd configuration templates, replacing
    ## variables in those templates with values from this scripts
    ## configuration files and returning them to the calling function.
    [[ ! -z "${DEBUG}" ]] && debug_function "${FUNCNAME[0]}" "$*"

    line="$@"

    ## construct the regular expression for configuration items
    local brm='([[:alpha:][:alnum:]_]*)[[:space:]]*\"\$\{(.*)\}\"$'
    ## match the regexp
    if [[ "${line}" =~ ${brm} ]] ; then
	## line is mpd configuration: `config_value "${...}"'
	
	## given a line of `config_value "${...}"'
	## the name of the variable with or without a default value: `...'
	var_part="${BASH_REMATCH[2]}"
	var_template="${var_part}"
	var_search="${var_template}"
	if [[ "${var_part}" =~ ^(.*):-(.*)$ ]]; then
	    ## the line contains a variable with default value:
	    ##  `config_value "${VARNAME:-default_value}"'

	    ## store the variable name: `VARNAME'
	    var_template="${BASH_REMATCH[1]}"
	    var_value="${BASH_REMATCH[2]}"
	    ## the variable name including its default value `VARNAME:-default_value'
	    var_search="${BASH_REMATCH[1]}:-${BASH_REMATCH[2]}"
	fi
	## assign the name of the variable (`VARNAME') to $expanded_name
	exp_name=var_template
	## assign the value of the variable (`$VARNAME') to $expanded_value
	local exp_value="${!exp_name}"
	## return the line with its real/expanded value
	if [[ ! -z "${!exp_value}" ]]; then
	    printf "%s" "${line//\$\{${var_search}\}/${!exp_value}}"
	else
	    [[ -z ${INCLUDE_COMMENTS} ]] && \
		printf "" || \
		printf "# %s (value not set)" "${line//\$\{${var_search}\}/${!exp_value}}"
	    [[ ! -z "${DEBUG}" ]] && \
		debug_configure "not writing empty configuration setting \`${var_template}'."
	fi
    else
	## a normal line; return it
	printf "%s" "${line}"
    fi
    
}

function source_enabled_confs() {
    ## source conf snippets in ./confs-enabled/*.conf while
    ## substituting the variables in those conf files with the ones
    ## generated in this script.
    [[ ! -z "${DEBUG}" ]] && debug_function "${FUNCNAME[0]}" "$*"

    ## temporary file needed to source enabled configuration snippets files
    tempconfs="$(mktemp)"
    ## fill the file with all configuration lines from `confs-enabled/*.conf`
    sed 's/^\([[:alnum:][:space:]_]*\)[[:space:]]*"\${\(.*\):-\(.*\)}"$/export \2="\${\2:-\3}"/' \
	${SCRIPT_DIR}/confs-enabled/*.conf | grep -E ^export > "${tempconfs}"
    ## source it (needed for variable expansion)
    source "${tempconfs}" || die_configure "could not source \`${tempconfs}'"
    ## remove it when DEBUG_CONFIGURE is not set
    [[ ! -z "${DEBUG}" ]] && \
	debug_configure "sourced configuration values stored in \`${tempconfs}'.\n" || \
	rm "${tempconfs}"

    ## iterate each file
    for conf_file in ${CONFS_ENABLED}; do
	[[ ! -z "${DEBUG}" ]] && debug_configure "${LINENO}: $(declare -p conf_file).\n"
	## check if the symlink points to a valid file
	conffile_path="$(readlink -f "${conf_file}")"
	if [[ ! -f "${conffile_path}" ]]; then
	    ## process the next one if the symlink is broken 
	    [[ ! -z "${DEBUG}" ]] && debug_configure "not a valid symlink \`${conf_file}'"
	    continue
	fi
	## the file exists, parse it
	printf "\n## start processing \`%s'\n" "${conf_file##*/}"
	## iterate each line
	while IFS='' read -r line ; do
	    ## skip commented lines
	    ## create trimmed version of line
	    if [[ -z ${INCLUDE_COMMENTS} ]]; then
		trimmed=$([[ "${line}" =~ [[:space:]]*([^[:space:]]|[^[:space:]].*[^[:space:]])[[:space:]]* ]]; echo -n "${BASH_REMATCH[1]}")
		if [[ "${trimmed#\#*}" = "${trimmed}" ]]; then
		    if [[ ! -z "${trimmed}" ]]; then
			## parse the line
			line="$(parse_configuration_line "${line}")"
			## original code
			[[ ! -z "${line}" ]] && \
			    printf "%s\n" "${line}"
		    fi
		fi
	    else
		line="$(parse_configuration_line "${line}")"
		printf "%s\n" "${line}"
	    fi
	done <${conf_file}
	printf "## done processing\n"
    done
}

function perform_automagic() {
    ### automagic configuration stuff
    [[ ! -z "${DEBUG}" ]] && debug_function "${FUNCNAME[0]}" "$*"

    ## client limits
    ## if the directory specified in `CONF_MPD_MUSICDIR` is
    ## accessible, calculate the number of audio files and double that
    ## for `max_playlist_length` parameter.
    
    default_length=${MAX_PLAYLIST_LENGTH_DEFAULT}
    nr_musicfiles=0

    if [[ "${G_CLIENTLIMITS_MAXPLAYLISTLENGTH}x" == "x" ]]; then
	[[ ! -z ${DEBUG} ]] && \
	    debug_configure "G_CLIENTLIMITS_MAXPLAYLISTLENGTH not set, trying to count the number of music files ..."
	## setting not configured
	[[ ! -z ${DEBUG} ]] && \
	    debug_configure "$(declare -p G_PATHS_MUSICDIRECTORY)"
	if [[ -d "${G_PATHS_MUSICDIRECTORY}" ]]; then
	    ## music dir exists; calculate number of files
	    ## TODO: add permission errors to errorlog
    	    ## ls without stat() calls is much faster than find or bash globbing, thanks 
	    ## http://stackoverflow.com/questions/1427032/fast-linux-file-count-for-a-large-number-of-files
	    let nr_musicfiles="$(ls -fR  "${G_PATHS_MUSICDIRECTORY}" 2>/dev/null | wc -l)"
	    [[ ! -z ${DEBUG} ]] && \
		debug_configure "Done counting, nr of files found: \`${nr_musicfiles}'"
	    let double_nr_musicfiles=$(( ${nr_musicfiles} * 2 ))
	    if [[ ${double_nr_musicfiles} -gt ${default_length} ]]; then
	 	G_CLIENTLIMITS_MAXPLAYLISTLENGTH="${double_nr_musicfiles}"
	    else 
		G_CLIENTLIMITS_MAXPLAYLISTLENGTH="${default_length}"
	    fi
	else
	    ## music dir not available; use default
	    G_CLIENTLIMITS_MAXPLAYLISTLENGTH="${default_length}"
	    [[ ! -z ${DEBUG} ]] && \
		debug_configure "Music dir not available, nr of files set to default: \`${G_CLIENTLIMITS_MAXPLAYLISTLENGTH}'."
	fi
    else
	[[ ! -z ${DEBUG} ]] && \
	    debug_configure "$(declare -p G_CLIENTLIMITS_MAXPLAYLISTLENGTH)"
    fi
    if [[ "${G_CLIENTLIMITS_MAXPLAYLISTLENGTH}x" != "x" ]]; then 
	## if empty set `G_CLIENTLIMITS_MAXCOMMANDLISTSIZE` to 1/8 of
	## `G_CLIENTLIMITS_MAXPLAYLISTLENGTH`
	if [[ "${G_CLIENTLIMITS_MAXCOMMANDLISTSIZE}x" == "x" ]]; then 
	    let G_CLIENTLIMITS_MAXCOMMANDLISTSIZE=$(( ${G_CLIENTLIMITS_MAXPLAYLISTLENGTH} / 8 ))
	fi
    	## if empty, set `MAXOUTPUTBUFFERSIZE` to 1/2 of
	## `G_CLIENTLIMITS_MAXPLAYLISTLENGTH`
	if [[ "${G_CLIENTLIMITS_MAXOUTPUTBUFFERSIZE}x" == "x" ]]; then 
	    let G_CLIENTLIMITS_MAXOUTPUTBUFFERSIZE=$(( ${G_CLIENTLIMITS_MAXPLAYLISTLENGTH} / 2 ))
	fi
    fi
    
    if [[ ! -z "${DEBUG}" ]]; then
	debug_configure "$(declare -p G_CLIENTLIMITS_MAXPLAYLISTLENGTH)"
	debug_configure "$(declare -p G_CLIENTLIMITS_MAXCOMMANDLISTSIZE)"
	debug_configure "$(declare -p G_CLIENTLIMITS_MAXOUTPUTBUFFERSIZE)"
    fi
    
    ## get network name for zeroconf
    if [[ -z "${G_ZEROCONF_ZEROCONFNAME}" ]]; then
	## `G_ZEROCONF_ZEROCONFNAME` is not set; set default zeroconf label 
	[[ ! -z ${DEBUG} ]] && \
	    debug_configure "G_ZEROCONF_ZEROCONFNAME not set  ..."
	
	hostname_string=""
	ipv6_re="*::*"
	## only try to get hostname if it isn't link local
	if [[ ! "${CONF_MPD_NETWORK_ADRESS}" =~ 127\. ]] || \
	       [[ "${CONF_MPD_NETWORK_ADRESS}" != "0.0.0.0" ]] || \
	       [[ ! "${CONF_MPD_NETWORK_ADRESS}" =~ ${ipv6_re}  ]]; then
	    ## mpd is configured to use a 'real' ip address; try to get fqdn name
	    [[ ! -z ${DEBUG} ]] && \
		debug_configure "mpd is configured to use a 'real' ip address ..."
	    CMD_HOSTNAME="$(type -p hostname)"
	    if [[ $? -eq 0 ]]; then
		hostname="$(${CMD_HOSTNAME})"
		[[ ! -z ${DEBUG} ]] && \
		    debug_configure "mpd hostname set by ${CMD_HOSTNAME} to \`${hostname}'."
	    fi
	    if [[ -z "${hostname}" ]]; then
		# use bash's internal hostname
		hostname="${HOSTNAME}"
		[[ ! -z ${DEBUG} ]] && \
		    debug_configure "mpd hostname set by script to HOSTNAME environment variable: \`${hostname}'."
	    fi
	else
	    [[ ! -z ${DEBUG} ]] && \
		debug_configure "${FUNCNAME[0]} (${LINENO}: \
$(declare -p G_ZEROCONF_ZEROCONFNAME) (set by user)"
	fi
	## set string to use if hostname contains something
	if [[ "${hostname}x" != "x" ]]; then
	    hostname_string="on ${hostname} "
	fi
	defname="MPD ${hostname_string}(${CONF_ALSA_AIF_DEVLABEL})"
	G_ZEROCONF_ZEROCONFNAME="${ZEROCONF_NAME:-${def_name}}"
		debug_configure "${FUNCNAME[0]} (${LINENO}: \
$(declare -p G_ZEROCONF_ZEROCONFNAME)"
	
	
    fi

    ## cap to the maximum nr of characters (64)
    G_ZEROCONF_ZEROCONFNAME="$(printf "%.*s\n" 64 "${G_ZEROCONF_ZEROCONFNAME}")"

    ## default directory depth for auto updates
    if [[ "${CONF_MPD_AUTOUPDATEDEPTH}x" == "x" ]]; then
	G_GENERAL_AUTOUPDATEDEPTH="$(getconf PATH_MAX "${G_PATHS_MUSICDIRECTORY}")"
    fi
}

function get_mpd_musicdir() {
    ### get and check music dir
    [[ ! -z "${DEBUG}" ]] && debug_function "${FUNCNAME[0]}" "$*"

    ## check if user set the music dir configuration parameters
    if [[ ! -z "${CONF_MPD_MUSICDIR}" ]]; then
        G_PATHS_MUSICDIRECTORY="${CONF_MPD_MUSICDIR}"
	[[ ! -z ${DEBUG} ]] && \
	    debug_configure "CONF_MPD_MUSICDIR set by user to \`${G_PATHS_MUSICDIRECTORY}'."
    else
	[[ ! -z ${DEBUG} ]] && \
	    debug_configure "CONF_MPD_MUSICDIR not set by user ..."
        
	## try getting the `MUSIC' directory from XDG and use that,
	## otherwise user current dir
	CMD_XDGUSERDIR="$(type -p xdg-user-dir)"
	if [[ $? -eq 0 ]]; then
	    [[ ! -z ${DEBUG} ]] && \
		debug_configure "CMD_XDGUSERDIR found in path: \`${CMD_XDGUSERDIR}'."
	    xdg_music_dir="$(${CMD_XDGUSERDIR} MUSIC)"
	    if [[ "$?" -eq 0 ]]; then
		G_PATHS_MUSICDIRECTORY="${xdg_music_dir}"
		[[ ! -z ${DEBUG} ]] &&  \
		    debug_configure "G_PATHS_MUSICDIRECTORY set to xdg-music-dir (${G_PATHS_MUSICDIRECTORY})"
	    else
		[[ ! -z ${DEBUG} ]] &&  \
		    debug_configure "G_PATHS_MUSICDIRECTORY left empty (${G_PATHS_MUSICDIRECTORY})"
            fi
	else
	    if [[ ! -z ${DEBUG} ]]; then
		debug_configure "CMD_XDGUSERDIR not found in path."
		debug_configure "G_PATHS_MUSICDIRECTORY left empty (${G_PATHS_MUSICDIRECTORY})"
	    fi
	fi
    fi
    
    ## use current dir if still empty
    if [[ -z ${G_PATHS_MUSICDIRECTORY} ]]; then
      G_PATHS_MUSICDIRECTORY="$(pwd)"
      [[ ! -z ${DEBUG} ]] && \
	  debug_configure "G_PATHS_MUSICDIRECTORY set to current dir: \`${G_PATHS_MUSICDIRECTORY}'."
    fi 
   
    check_readable_path "${G_PATHS_MUSICDIRECTORY}" "music directory" "listen to music"
    
}

function get_current_mpdconf_path() {
    ## get and return the mpd.conf file in use by the system
    [[ ! -z "${DEBUG}" ]] && debug_function "${FUNCNAME[0]}" "$*"

    ## for debian based distros 
    default_path="/etc/default/mpd"
    default_re="[[:space:]]*MPDCONF[[:space:]]*=[[:space:]]*(.*)"
    conffile=""
    declare -a default_mpd_conf_paths
    if [[ "${XDG_CONFIG_HOME}x" == "x" ]]; then
	XDG_CONFIG_HOME="~/.config"
    fi
    declare -a default_mpd_conf_paths=(
	"${XDG_CONFIG_HOME}/mpd/mpd.conf"
	"~/.mpdconf"
	"~/.mpd/mpd.conf"
	"/etc/mpd.conf")
    if [[ "${CONF_MPD_CONFFILE}x" != "x" ]]; then
	if [[ -f "${default_path}" ]]; then
	    while read -r line; do
		if [[ "${line}" =~ ${default_re} ]]; then
		    [[ ! -z "${DEBUG}" ]] && \
			debug_configure "${FUNCNAME[0]}: default ${MSG_CONF_TITLE}: \`${conffile}'."
		    conffile="${BASH_REMATCH[1]}"
		    break
		fi
	    done<"${default_path}"
	fi

	if [[ "${conffile}x" != "x" ]]; then
	    if [[ ! -f "${conffile}" ]]; then
		[[ ! -z "${DEBUG}" ]] && \
		    debug_configure "${FUNCNAME[0]}: default ${MSG_CONF_TITLE} \`${conffile}' \
does not exist."
		## default conffile does not exist
	    else
		[[ ! -z "${DEBUG}" ]] && \
		    debug_configure "${FUNCNAME[0]}: default ${MSG_CONF_TITLE} \`${conffile}' exists."
	    fi
	else
	    ## no default conffile, try usual suspects  
	    for conffile in "${default_mpd_conf_paths[@]}"; do
		if [[ -f "${conffile}" ]]; then
		    [[ ! -z "${DEBUG}" ]] && \
			debug_configure "${FUNCNAME[0]}: non-default ${MSG_CONF_TITLE} \`${conffile}' found."
		    break
		fi
	    done
	fi
    fi

    if [[ "${conffile}x" == "x" ]]; then
	conffile="${default_mpd_conf_paths[0]}"
	[[ ! -z "${DEBUG}" ]] && \
	    debug_configure "${FUNCNAME[0]}: no ${MSG_CONF_TITLE} found; will use the first default one: ${conffile}."	
    fi
    
    if [[ -f "${conffile}" ]]; then
	[[ ! -z "${DEBUG}" ]] && \
	    debug_configure "${FUNCNAME[0]}: ${MSG_CONF_TITLE} \`${conffile}' exists."
	printf "%s" "${conffile}"
    else
	[[ ! -z "${DEBUG}" ]] && \
	    debug_configure "${FUNCNAME[0]}: ${MSG_CONF_TITLE} \`${conffile}' does not (yet) exist."
	printf "%s" "${conffile}"
    fi
	
}


function get_mpd_homedir() {
    ### get and check working directory for mpd
    ##  according to mpd source
    [[ ! -z "${DEBUG}" ]] && debug_function "${FUNCNAME[0]}" "$*"
  
    ## if `CONF_MPD_HOMEDIR` not set by user use `XDG_CONFIG_MPDDIR`
    if [[ "${CONF_MPD_HOMEDIR}x" != "x" ]]; then
	[[ ! -z ${DEBUG} ]] && \
	    debug_configure "CONF_MPD_HOMEDIR set by user to \`${CONF_MPD_HOMEDIR}'."
    else
	CONF_MPD_HOMEDIR="$(dirname "$(get_current_mpdconf_path)")"
	[[ ! -z ${DEBUG} ]] && \
	    debug_configure "CONF_MPD_HOMEDIR set by script to \`${CONF_MPD_HOMEDIR}'."
    fi	
    ## check if it is accessible or can be made
    ## where to store data
    MPD_DATADIR="${MPD_DATADIR:-${CONF_MPD_HOMEDIR}}"
    CONF_MPD_PLAYLISTDIR="${MPD_PLAYLISTDIR:-${MPD_DATADIR}/playlists}"
    CONF_MPD_DBFILE="${MPD_DBFILE:-${MPD_DATADIR}/tag_cache}"
    CONF_MPD_LOGFILE="${MPD_LOGFILE:-${MPD_DATADIR}/mpd.log}"
    CONF_MPD_PIDFILE="${MPD_PIDFILE:-${MPD_DATADIR}/pid}"
    CONF_MPD_STATEFILE="${MPD_STATEFILE:-${MPD_DATADIR}/state}"
    CONF_MPD_STICKERFILE="${MPD_STICKERFILE:-${MPD_DATADIR}/sticker}"
}


function conf_header() {
    ## construct the byline for the configuration file
    [[ ! -z "${DEBUG}" ]] && debug_function "${FUNCNAME[0]}" "$*"

    formatted_date="$(date -Is)"

    printf "\n%s\n%s begin of %s\n%s created by \`%s' (version %s) on %s.\n%s see: %s\n%s" \
	"${MSG_CONF_LINESEP}" "${MSG_CONF_SEP}" "${MSG_CONF_TITLE}" \
	"${MSG_CONF_SEP}" "${APP_NAME_MPDCONFIGURE}" "${APP_VERSION_MPDCONFIGURE}" "${formatted_date}" \
	"${MSG_CONF_SEP}" "${APP_URL}" "${MSG_CONF_LINESEP}"

}

function conf_footer() {
    ## construct the footer for the configuration file
    [[ ! -z "${DEBUG}" ]] && debug_function "${FUNCNAME[0]}" "$*"

    printf "\n\n%s\n%s end of %s\n%s" \
	"${MSG_CONF_LINESEP}" "${MSG_CONF_SEP}" \
	"${MSG_CONF_TITLE}" "${MSG_CONF_LINESEP}"
}


function do_configure() {
    ## main function
    [[ ! -z "${DEBUG}" ]] && debug_function "${FUNCNAME[0]}" "$*"

    analyze_command_line_conf "$@" || exit 

    ## fill the ALSA_AIF_HWADDRESSES and ALSA_AIF_DEVLABELS arrays and
    ## get a count of number of audio output interfaces
    fetch_alsa_hwaddresses
    if [[ $? -ne 0 ]]; then
	die_configure "${FUNCNAME[0]}: error running \`fetch_alsa_hwaddresses'"
    else
	interface_count=${#ALSA_AIF_HWADDRESSES[@]}
    fi
    [[ ! -z ${DEBUG} ]] && \
	debug_configure "${FUNCNAME[0]}: fetch_alsa_hwaddresses returned ${interface_count} interfaces."

    ## get the index number of the selected hardware address in the
    ## ALSA_AIF_HWADDRESSES array
    selected_array_index="$(select_interface_index "${interface_count}")"
    if [[ $? -ne 0 ]]; then
	## select_interface_index returned a descriptive error
	die_configure "${selected_array_index}"
    else
	## store the hardware address and label for usage in audio_conf
	CONF_ALSA_AIF_HWADDRESS="${ALSA_AIF_HWADDRESSES[${selected_array_index}]}"
	CONF_ALSA_AIF_DEVLABEL="${ALSA_AIF_DEVLABELS[${selected_array_index}]} - \
${ALSA_AIF_LABELS[${selected_array_index}]}"
    fi
    [[ ! -z ${DEBUG} ]] && \
	debug_configure "${FUNCNAME[0]}: CONF_ALSA_AIF_HWADDRESS=\`${CONF_ALSA_AIF_HWADDRESS}'."

    if [[ ! -z "${CONF_MPD_CONFFILE}" ]]; then 
	default_mpd_conffile="$(get_current_mpdconf_path "${CONF_MPD_CONFFILE}")"
	if [[ $? -eq 0 ]]; then
	    if [[ "${CONF_MPD_CONFFILE}" != "${default_mpd_conffile}" ]]; then
		printf " %s output %s set to \`%s', but according to system\n" \
		   "-" "${MSG_MPD_CONFFILE}" "${CONF_MPD_CONFFILE}" 1>&2;
		printf "   \`%s' will be used by mpd by default. " \
		       "${default_mpd_conffile}" 1>&2;
		printf "%s in order to use the new file, \n   start mpd with:\n" "-" 1>&2;
		printf "     mpd [other options] %s\n" \
		       "${CONF_MPD_CONFFILE}" 1>&2;
		printf "   or rerun this script and set the \`--output' option to \`%s'.\n" \
		       "${CONF_MPD_CONFFILE}"
	    fi
	fi
    fi

    ## get and check paths
    get_mpd_musicdir
    [[ $? -eq 0 ]] || die_configure "error in get_mpd_musicdir."

    ## get and check paths
    get_mpd_homedir 
    [[ $? -eq 0 ]] || die_configure "error in get_mpd_homedir."

    ### perform automagic configuration
    perform_automagic
    [[ $? -eq 0 ]] || die_configure "error in perform_automagic."

    [[ ! -z ${DEBUG} ]] && \
	debug_configure "done with perform_automagic."
    
    ## store conf snippets in `CONF_CONTENTS`
    header="$(conf_header)"
    footer="$(conf_footer)"

    ## iterate each line in enabled files in `confs-enabled/*.conf`
    CONF_CONTENTS="${header}$(source_enabled_confs)${footer}"

    ## displays the contents of CONF_CONTENTS or write them to
    ## `CONF_MPD_CONFFILE` if set
    if [[ ! -z "${CONF_MPD_CONFFILE}" ]]; then
	[[ ! -z ${DEBUG} ]] && \
	    debug_configure "CONF_MPD_CONFFILE set to \`${CONF_MPD_CONFFILE}'."
	 
	res="$(write_conffile "${CONF_MPD_CONFFILE}")"
	printf "%s\n" "${res}"
    else
	[[ ! -z ${DEBUG} ]] && \
	    debug_configure "CONF_MPD_CONFFILE left empty; printing to std_out."
	## display the results (print to std_out)
	printf "%s\n" "${CONF_CONTENTS}"
    fi

    exit
}

function display_usageinfo_conf() {
    ## display syntax and exit
    [[ ! -z ${DEBUG} ]] && \
	debug_function_ac "${FUNCNAME[0]}" "$*"

    msg=$(cat <<EOF
Usage:
$0 [-o PATH] [-l a|d|u] [-c REGEXP] [-a HWADDRESS] [-q] [--nobackup]

Creates a valid configuration file for mpd, in which the audio
configuration parameters are set for bit perfect playback. Without any
settings the results are printed to stdout.

The scripts lists all available alsa playback devices on the host. If
multiple are found, the user is prompted to enter the hardware address
of the device to be used. The \`-n' (\`--noprompts') option skips the
prompt and uses the first interface found instead. The \`-l'
(\`--limit'), \`-c' (\`--customfilter') and \`-a' (\`--address') may
be used to filter the returned alsa devices.

  -o PATH, --outputfile PATH    
                     Saves the result in the file specified with
                     \`PATH'. When this is an existing file, the
                     scripts prompts the user to overwrite it, and
                     makes a backup of the original file unless the
                     \`--nobackup' option is used).
  -l TYPEFILTER, --limit TYPEFILTER   
                     Limit the list of available audio interfaces to
                     TYPEFILTER. Can be one of \`a' (or \`analog'),
                     \`d' (or \`digital'), \`u' (or \`usb'), the
                     latter for USB Audio Class (UAC1 or UAC2)
                     devices.
  -c REGEXP, --customlimit REGEXP 
                     Limit the list further to match \`REGEXP'.
  -a HWADDRESS, --address HWADDRESS   
                     Limits the list further by the audio interface
                     specified with HWADDRESS, eg. \`hw:0,1'.
  -q, --quiet        Surpress listing each interface with its details,
                     ie. only store the details of each card in the
                     appropriate arrays.
  -n, --noprompts    Surpress prompting for the interface to use
                     and/or to overwrite an existing conffile. Use the
                     first available interface (matching the filters)
                     instead.
  --nobackup         By default the scripts backs up an existing
                     output file before overwriting. Setting this
                     option prevents that and overwrites the file
                     without making a backup.
  -h, --help         Show this help message and exit.
EOF
)
    printf "%s\n" "${msg}" 1>&2;
}


function analyze_command_line_conf() {
    ## parse command line arguments using the `manual loop` method
    ## described in http://mywiki.wooledge.org/BashFAQ/035.
    [[ ! -z ${DEBUG} ]] && \
	debug_function_ac "${FUNCNAME[0]}" "$*"

    while :; do
        case "${1:-}" in
            -o|--output)
		if [ -n "${2:-}" ]; then
		    [[ ! -z ${DEBUG} ]] && \
			debug "$(printf "option \`%s' set to \`%s'.\n" "$1" "$2")"
		    CONF_MPD_CONFFILE="$2"
		    shift 2
                    continue
		else
		    ## in alsa-capabilities
		    analyze_opt_limit "$1"
                    exit 1
		fi
		;;
            -l|--limit)
		if [ -n "${2:-}" ]; then
		    [[ ! -z ${DEBUG} ]] && \
			debug "$(printf "option \`%s' set to \`%s'.\n" "$1" "$2")"
		    OPT_LIMIT="True"
		    analyze_opt_limit "$1" "$2"
		    shift 2
                    continue
		else
		    ## in alsa-capabilities
		    analyze_opt_limit "$1"
                    exit 1
		fi
		;;
	    -c|--customfilter)
		if [ -n "${2:-}" ]; then
		    [[ ! -z ${DEBUG} ]] && \
			debug "$(printf "option \`%s' set to \`%s'.\n" "$1" "$2")"
		    OPT_FILTER="${2}"
		    shift 2
                    continue
		else
                    printf "ERROR: option \`%s' requires a non-empty argument.\n" "$1" 1>&2
                    exit 1
		fi
		;;
            -a|--address)
		if [ -n "${2:-}" ]; then
		    [[ ! -z ${DEBUG} ]] && \
			debug "option \`$1' set to \`$2'"
		    OPT_HWFILTER="$2"
		    shift 2
                    continue
		else
                    printf "ERROR: option \`%s' requires a alsa hardware address \
as an argument (eg \`hw:x,y')\n" "$1" 1>&2
                    exit 1
		fi
		;;
	    -q|--quiet|--silent)
		[[ ! -z ${DEBUG} ]] && \
		    debug "option \`$1' set"
		OPT_QUIET=true
		shift 
                continue
		;;
	    -n|--noprompts|--noprompt)
		[[ ! -z ${DEBUG} ]] && \
		    debug "option \`$1' set"
		DISABLE_PROMPTS=true
		shift 
                continue
		;;
	    --nobackup|--no-backup)
		[[ ! -z ${DEBUG} ]] && \
		    debug "option \`$1' set"
		SKIP_BACKUP=true
		shift 
                continue
		;;	    
	    -h|-\?|--help) 
		display_usageinfo_conf
		exit
		;;
           --)
	       shift
	       break
	       ;;
	   -?*)
	       printf "Notice: unknown option \`%s' ignored\n\n." "$1" 1>&2
               display_usageinfo_conf
	       exit
               ;;
           *)
               break
        esac
    done

}


### program start

## check if we're re being sourced
SOURCED=""

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SOURCED=True 
    ## store the current directory 
    SCRIPT_DIR=$(pwd)
    [[ ! -z ${DEBUG} ]] && \
	debug_configure "script ${0} is being sourced; using SCRIPT_DIR \`${SCRIPT_DIR}'."
else
    ## store the directory in which the script resides
    SCRIPT_DIR=$(dirname $0)
    [[ ! -z ${DEBUG} ]] && \
	debug_configure "script ${0} is being run; using SCRIPT_DIR \`${SCRIPT_DIR}'."
fi

if [[ ! -z ${DEBUG} ]]; then
    debug_configure "debugging turned on by user."
fi

## no problem if GNU find is not found; fail silently


## source own helper script if found
ALSA_CAPABILITIES_FILE="alsa-capabilities.sh"
ALSA_CAPABILITIES_SCRIPT="${SCRIPT_DIR}/${ALSA_CAPABILITIES_FILE}"

if [[ -f "${ALSA_CAPABILITIES_SCRIPT}" ]]; then 
    [[ ! -z ${DEBUG} ]] && \
	debug_configure "will source ALSA_CAPABILITIES_SCRIPT \`${ALSA_CAPABILITIES_SCRIPT}' ..."
    source "${ALSA_CAPABILITIES_SCRIPT}" 
    if [[ $? -eq 0 ]]; then
	[[ ! -z ${DEBUG} ]] && debug_configure "... done."
    else
	die_configure "error sourcing ALSA_CAPABILITIES_SCRIPT \`${ALSA_CAPABILITIES_SCRIPT}'."
    fi
else
    die_configure "required script \`${ALSA_CAPABILITIES_SCRIPT}' not found."
fi

## ugly temporary hack; see gitlab issue #8
set +u
set +e

## list of enabled configuration snippet files
CONFS_ENABLED=${SCRIPT_DIR}/confs-enabled/*.conf
[[ ! -z ${DEBUG} ]] && debug_configure "CONFS_ENABLED: \`${CONFS_ENABLED}'."

## global indexed arrays that will be filled from `alsacapabilities.sh'
declare -a ALSA_AIF_HWADDRESSES=()
declare -a ALSA_AIF_DEVLABELS=()
declare -a ALSA_AIF_LABELS=()

## for storing (potential) problems 
declare -a PROBLEMS=()

## set to non empty to disable prompting 
DISABLE_PROMPTS="${DISABLE_PROMPTS:-}"
## set to non empty to overwrite an existing conf file without making
## a backup, which it does when only DISABLE_PROMPTS is set
SKIP_BACKUP="${SKIP_BACKUP:-}"
TEMP_CONF_BACKUP="${TEMP_CONF_BACKUP:-}"

## source the config file if its present
PREFERENCES_FILE="${SCRIPT_DIR}/mpd-configure.conf"
if [[ -f "${PREFERENCES_FILE}" ]]; then
    source "${PREFERENCES_FILE}"
    [[ ! -z ${DEBUG} ]] && \
	debug_configure "PREFERENCES_FILE sourced: \`${PREFERENCES_FILE}'"
else
    [[ ! -z ${DEBUG} ]] && \
	debug_configure "PREFERENCES_FILE \`${PREFERENCES_FILE}' not found."
fi

CONF_MPD_CONFFILE="${CONF_MPD_CONFFILE:-}"

## for backwards compatibility
[[ ! -z "${CONF_ZEROCONF_ENABLED}" ]] || [[ ! -z "${ENABLE_LASTFM}" ]] && \
    die_configure "configuration settings \`CONF_ZEROCONF_ENABLED' and
    \`ENABLE_LASTFM' \nare no longer valid. please consult \`README'."

## for backwards compatibility
if [[ ! -z "${CONF_MPD_HOST}" ]] || [[ ! -z "${CONF_MPD_NETWORK_ADRESS}" ]]; then
    if [[ ! -z "${CONF_MPD_HOST}" ]] && [[ ! -z "${CONF_MPD_NETWORK_ADRESS}" ]]; then
	[[ ! -z ${DEBUG} ]] && \
	    "Both CONF_MPD_HOST and CONF_MPD_NETWORK_ADRESS set by user, using the latter"
	G_NETWORK_BINDTOADDRESS="${CONF_MPD_NETWORK_ADRESS}"
	[[ ! -z ${DEBUG} ]] && \
	    debug_configure "CONF_MPD_NETWORK_ADRESS set by user to: \`${CONF_MPD_NETWORK_ADRESS}'."
    else
	
	if [[ ! -z "${CONF_MPD_HOST}" ]]; then
	    CONF_MPD_NETWORK_ADRESS="${CONF_MPD_HOST}"
	    G_NETWORK_BINDTOADDRESS="${CONF_MPD_NETWORK_ADRESS}"
	    [[ ! -z ${DEBUG} ]] && \
		debug_configure "CONF_MPD_NETWORK_ADRESS set by user through CONF_MPD_HOST to: \`${CONF_MPD_HOST}'."
	fi
	if [[ ! -z "${CONF_MPD_NETWORK_ADRESS}" ]]; then
	    G_NETWORK_BINDTOADDRESS="${CONF_MPD_NETWORK_ADRESS}"
	    [[ ! -z ${DEBUG} ]] && \
		debug_configure "CONF_MPD_NETWORK_ADRESS set by user to: \`${CONF_MPD_NETWORK_ADRESS}'."
	fi
    fi
else
    ## both not set; default
    CONF_MPD_NETWORK_ADRESS="${CONF_MPD_NETWORK_ADRESS_DEFAULT}"
    G_NETWORK_BINDTOADDRESS="${CONF_MPD_NETWORK_ADRESS}"
    [[ ! -z ${DEBUG} ]] && \
	debug_configure "CONF_MPD_NETWORK_ADRESS set to default: \`${CONF_MPD_NETWORK_ADRESS}'."
fi

if [[ ! -z "${CONF_ZEROCONF_LABEL}" ]]; then 
    G_ZEROCONF_ZEROCONFNAME="${CONF_ZEROCONF_LABEL}"
    [[ ! -z ${DEBUG} ]] && \
	debug_configure "G_ZEROCONF_ZEROCONFNAME set to CONF_ZEROCONF_LABEL: \`${CONF_ZEROCONF_LABEL}'"
fi
## global variable for holding the contents of the conf file
CONF_CONTENTS=""

## general messages and fixed strings
MSG_MPD_CONFFILE="mpd configuration file"
MSG_CONF_LINESEP="$(printf '#%.0s' {1..76})"
MSG_CONF_SEP="###"
MSG_CONF_TITLE="mpd configuration file"


## pass limits to the alsa-capabilities script
if [[ ! -z ${LIMIT_INTERFACE_TYPE} ]]; then
    case ${LIMIT_INTERFACE_TYPE} in
	"analog")
	    OPT_LIMIT_AO="True"
	    [[ ! -z ${DEBUG} ]] && \
		debug_configure "Only process analog interfaces (OPT_LIMIT_AO): ${OPT_LIMIT_AO}"
	    ;;
	
	"digital")
	    OPT_LIMIT_DO="True" 
	    [[ ! -z ${DEBUG} ]] && \
		debug_configure "Only process digital interfaces (OPT_LIMIT_DO): ${OPT_LIMIT_DO}"
	    ;;
	"usb"|"uac")
	    OPT_LIMIT_UO="True" 
	    [[ ! -z ${DEBUG} ]] && \
		debug_configure "Only process usb interfaces (OPT_LIMIT_UO): ${OPT_LIMIT_UO}"
	    ;;
    esac
fi

if [[ ! -z ${LIMIT_INTERFACE_FILTER} ]]; then
    OPT_FILTER="${LIMIT_INTERFACE_FILTER}"
    [[ ! -z ${DEBUG} ]] && \
	debug_configure "OPT_FILTER set to LIMIT_INTERFACE_FILTER: \`${LIMIT_INTERFACE_FILTER}'"
fi

## display (potential) problematic situations, like no right access to
## files and directories
if [[ ! -z "${DEBUG}" ]]; then
    if [[ ${#PROBLEMS[@]} -gt 0 ]]; then
	debug_configure "\nPotential problems found:\n${PROBLEMS[*]}"
    else
	debug_configure "No potential problems found."
    fi
fi

## if the script is sourced do nothing, otherwise run main flow
if [[ -z "${SOURCED}" ]]; then
    [[ ! -z ${DEBUG} ]] && \
	debug_configure "start main function \`do_configure' ..."

    do_configure "$@"

    [[ ! -z ${DEBUG} ]] && \
	debug_configure "... main function \`do_configure' done."
else
    [[ ! -z ${DEBUG} ]] && \
	debug_configure "you may run main function \`do_configure'."
    
fi

### done