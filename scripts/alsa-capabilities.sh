#!/usr/bin/env bash
## 
## This script for linux with bash 4.x displays a list with the audio
## capabilities of each alsa audio output and stores them in
## arrays for use in other scripts.  This functionality is exposed by
## the `main' function which is avaliable after
## sourcing the file. When ran from a shell, it will call that
## function.
##
##  Copyright (C) 2019 Ronald van Engelen <ronalde+gitlab@lacocina.nl>
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
## Source:    https://gitlab.com/sonida/alsa-capabilities
## See also:  https://lacocina.nl/detect-alsa-output-capabilities

LANG=C

APP_NAME_AC="alsa-capabilities"
APP_VERSION="2.0.1"
APP_DEV_URL="https://gitlab.com/sonida/alsa-capabilities/"
APP_INFO_URL="https://lacocina.nl/detect-alsa-output-capabilities"

## set DEBUG to a non empty value to display internal program flow to
## stderr
DEBUG="${DEBUG:-}"
## to see how the script behaves with a certain output of aplay -l
## on a particular host, store it's output in a file and supply
## the file path as the value of TESTFILE, eg:
## `TESTFILE=/tmp/somefile ./bash-capabilities
## All hardware and device tests will fail or produce fake outputs
## (hopefully with some grace).
TESTFILE="${TESTFILE:-}"

### generic functions
function die() {
    printf 1>&2 "\n${c_bold}${c_red}%s error${c_std} in ${c_bold}${c_yellow}%s${c_std}${c_dim}:${c_std}${c_white}\n%s\n\n" \
                "${APP_NAME_AC}" \
                "${FUNCNAME[1]}" \
                "$@"
    exit 1
}

function debug() {
    linenumber="$1"
    message="${2:-}"
    scriptname="${APP_NAME_AC}"
    [[ ${OPT_SOURCED} ]] || scriptname=""
    [[ ${DEBUG} ]] && 
        printf 1>&2 "${c_dim}[D${c_blue}%s${c_dim}:${c_bold}${c_green}%29s${c_std} ${c_dim}${c_std}${c_blue}%04d${c_std}${c_dim}]${c_std} %s\n" \
		    "${scriptname}" \
                    "${FUNCNAME[1]}" \
		    "${linenumber}" \
		    "${message}"
    return 0
}


function trim() {
    ## trims leading and trailing spaces from $1
    text="$1"
    shopt -s extglob
    text="${text##+([[:space:]])}"
    text="${text%%+([[:space:]])}"
    printf "%s" "${text}"
}


function cleanup() {
    ## called by EXIT trap
    ## restore the state of alsa to the stored one
    if [[ -f "${ALSA_STATEFILE}" ]]; then
        alsactl restore -f "${ALSA_STATEFILE}" >/dev/null 2>&1
        rm -f "${ALSA_STATEFILE}" >/dev/null 1>&2
        debug "${LINENO}" "${ALSA_STATEFILE} restored and removed"
    else
        debug "${LINENO}" "nothing to do (no statefile exists)."
    fi
}

function alsa_mute() {
    ## if alsactl is present, store the original state in a
    ## tmpfile; next mute the Master control
    debug "${LINENO}" "trying to mute the Master control"
    type -p alsactl  >/dev/null 2>&1 || return 1
    ALSA_STATEFILE="$(mktemp "/tmp/${APP_NAME_AC}.XXXXX.alsa.state")"
    alsactl store -f "${ALSA_STATEFILE}" >/dev/null 2>&1 || return 1
    amixer set Master mute >/dev/null 2>&1 || return 1
    debug "${LINENO}" "Master control muted: original state saved in \`${ALSA_STATEFILE}'."
}

### command line parsing

function display_usageinfo() {
    msg="
Usage:
${APP_NAME_AC} [ -l a|d|u ]  [ -c <filter> ] [-a <hwaddress>] [-s] [ -q ]

Displays a list of each alsa audio output with its details
including its hardware address (eg. \`hw:x,y').

The list may be limited by applying one or more options with
arguments, for the type of output (\`-l' or \`--limit'), the name of
the card and/or output (\`-c' or \`--customfilter'), and/or the
hardware address (\`-a\ or \`--address').

The \`-s' or \`--samplerates' switch turns on the detection and
display of the supported samplerates per encoding format for each
output.

  -l TYPEFILTER, --limit TYPEFILTER
                     Limit the interfaces to TYPEFILTER. Can be one of
                     \`a' (or \`analog'), \`d' (or \`digital'), \`u'
                     (or \`usb'), the latter for USB Audio Class (UAC1
                     or UAC2) devices.
  -c REGEXP, --customlimit REGEXP
                     Limit the available interfaces further to match
                     \`REGEXP'.
  -a HWADDRESS, --address HWADDRESS
                     Limit the returned interface further to the one
                     specified with HWADDRESS, eg. \`hw:0,1'
  -s, --samplerates  Adds a listing of the supported sample rates for
                     each format an interface supports. 
  -q, --quiet        Surpress listing each interface with its details,
                     ie. only store the details of each card in the
                     appropriate arrays.
  -j, --json         Surpress normal output but create json formatted
                     output instead.
  -n, --nocolor      Supresses colorized output.
  -h, --help         Show this help message

Version ${APP_VERSION}. For more information see:
${APP_INFO_URL}
${APP_DEV_URL}
"
    printf "%s\n" "${msg}" 1>&2;
}

function analyze_command_line() {
    ## parse command line arguments using the `manual loop` method
    ## described in http://mywiki.wooledge.org/BashFAQ/035.
    while :; do
        [[ "${1:-x}" == "x" ]] || \
            debug "${LINENO}" "switch \`${1:-}' set to \`${2:-}'."
        case "${1:-}" in
            -l*)
                ## TYPEFILTER
		if [[ -n "${2:-}" ]]; then
		    #analyze_opt_limit "$1" "$2"
                    case "$2" in
                        a*)  OPT_FILTER_DEVTYPE="${DEVTYPE_ANALOG}" ;;
                        d*)  OPT_FILTER_DEVTYPE="${DEVTYPE_DIGITAL}" ;;
                        u*)  OPT_FILTER_DEVTYPE="${DEVTYPE_UAC}" ;;
                        *)
                            die "Invalid argument \`$2' for option \`$1' specified."
                    esac
                    debug "${LINENO}" "OPT_FILTER_DEVTYPE=\`${OPT_FILTER_DEVTYPE}'"
		    shift 2
                    continue
		else
                    die "Option  \`$1' needs an argument."
		fi
		;;
	    -c*)
                ## CUSTOMFILTER
		if [[ -n "${2:-}" ]]; then
		    OPT_FILTER_CUSTOM="${2}"
                    debug "${LINENO}" "OPT_FILTER_CUSTOM=\`${OPT_FILTER_CUSTOM}'"
		    shift 2
                    continue
		else
                    printf "ERROR: option \`%s' requires a non-empty argument.\n" "$1" 1>&2
                    exit 1
		fi
		;;
            -a*)
                ## HWADDRESSFILTER
		if [[ -n "${2:-}" ]]; then
		    OPT_FILTER_HWADDRESS="$2"
                    debug "${LINENO}" "OPT_FILTER_HWADDRESS=\`${OPT_FILTER_HWADDRESS}'"
		    shift 2
                    continue
		else
                    printf "ERROR: option \`%s' requires a alsa hardware address \
as an argument (eg \`hw:x,y')\n" "$1" 1>&2
                    exit 1
		fi
		;;
            -s|--samplerates)
		OPT_SAMPLERATES=true
                debug "${LINENO}" "OPT_SAMPLERATES=\`${OPT_SAMPLERATES}'"
		shift
                continue
		;;
	    -q|--quiet|--silent)
		OPT_QUIET=true
                debug "${LINENO}" "OPT_QUIET=\`${OPT_QUIET}'"
		shift
                continue
		;;
	    -j|--json)
		OPT_JSON=true
                debug "${LINENO}" "OPT_JSON=\`${OPT_JSON}'"
		shift
                continue
		;;
	    -n|--nocolor)
		OPT_NOCOLOR=true
                debug "${LINENO}" "OPT_NOCOLOR=\`${OPT_NOCOLOR}'"
		shift
                continue
		;;
	    -h|-\?|--help)
		display_usageinfo
		exit
		;;
            --)
		shift
		break
		;;
	    -?*)
		printf "Notice: unknown option \`%s' ignored\n\n." "$1" 1>&2
		display_usageinfo
		exit
		;;
            *)
		break
        esac
    done
}

### output related functions

function set_colors() {
    ## TODO: using multiple tput calls is way too expensive (0.003 per call)
    if ! tput sgr0 2>/dev/null 1>&2; then
        OPT_NOCOLOR=true
        debug "${LINENO}" "tput not supported on TERM=\`${TERM}'; OPT_NOCOLOR set"
    fi
    if [[ ${OPT_NOCOLOR} ]]; then
        c_bold=""
        c_dim=""
        c_std=""
        c_red=""
        c_green=""
        c_yellow=""
        c_blue=""
        c_white=""
    else        
        c_bold="$(tput bold 2>/dev/null)"
        c_dim="$(tput dim 2>/dev/null)"
        c_std="$(tput sgr0 2>/dev/null)"
        c_red="$(tput setaf 1 2>/dev/null)"
        c_green="$(tput setaf 2 2>/dev/null)"
        c_yellow="$(tput setaf 3 2>/dev/null)"
        c_blue="$(tput setaf 4 2>/dev/null)"
        c_white="$(tput setaf 7 2>/dev/null)"
    fi
}

### json output

function ret_json_attribute() {
    ## returns a json "key": "val" attribute pair.
    key="$1"
    val="$2"
    ## check if val is a number
    if printf -v numval "%d" "${val}" 2>/dev/null; then
	## it is
	printf '"%s": %d' \
	       "${key}" "${numval}"
    else
	printf '"%s": "%s"' \
	       "${key}" "${val}"
    fi
}

function json_nest() {
    ## turn a bash array in to a json comma separated list
    argcount="$#"
    argcounter=0
    while :; do
        printf "%s" "$1"
        (( argcounter > argcount - 2 )) && break
        printf ",\n"
        shift
        ((argcounter++))
    done<<<"$1"
}

function ret_json_group() {
    ## returns a json object or array;
    ## when group_name in $1 is non-empty: a named object or array, eg
    ##   '"group_name": { ... }' or '"group_name": [ ... ]'
    ## otherwise just:
    ##   '{ ... }' or '[ ... ]'.
    ## group_type in $2 defines whether an object '{...}' or array '[...]' is returned.
    group_name="$1"
    group_type="$2"
    ## remainder of arguments ($@) contains group items
    shift 2
    json_name=""
    if [[ "${group_type}" == "array" ]]; then
        group_start="["
        group_end="]"
    else
        group_start="{"
        group_end="}"
    fi
    ## fill/format group name if needed
    [[ ${group_name} ]] && printf -v json_name "\"%s\": " "${group_name}"
    printf "%s%s \n%s\n %s\n" \
           "${json_name}" \
           "${group_start}" \
           "$(json_nest "$@")" \
           "${group_end}"
}

function ret_json_formats() {
    ## returns a named json array, each item representing a format and/or samplerate for an audio output.
    ## with OPT_SAMPLERATES: "encoding_formats": [ { "FORMAT1": [SR1, SR2]}, { "FORMAT2": [SR1, SR2] } ]
    ## without:              "encoding_formats": [ "FORMAT1", "FORMAT2" ]
    idx="${1}"
    declare -a json_formats=()
    if [[ ${OPT_SAMPLERATES} ]]; then
        while read -r line; do
            [[ ${line} ]] || break
            IFS="," read -r -a samplerates <<< "${line##*:}"
            json_formats+=("{ \"${line%%:*}\": [ $(json_nest "${samplerates[@]}") ] }")
        done < <(echo -e "${ALSA_FORMATS[${idx}]}\n")
    else
        declare -a json_rawformats=()
        IFS="," read -r -a json_rawformats <<< "${ALSA_FORMATS[${idx}]}"
        for json_rawformat in "${json_rawformats[@]}"; do
            json_formats+=("\"${json_rawformat}\"")
        done
    fi
    debug "${LINENO}" "$(declare -p json_formats)"
    #ret_json_array "encoding_formats" "$(json_nest "${jformats[@]}")"
    #_ret_json_array "encoding_formats" "${jformats[@]}"
    ret_json_group "encoding_formats" "array" "${json_formats[@]}"
}

function ret_json_paths() {
    ## returns a named json object, with the path attributes for the audio output with idx $1
    idx="$1"
    declare -a json_paths=()
    json_paths+=("$(ret_json_attribute "hwparams" "${ALSA_PATHS_HWPARAMS[${idx}]}")")
    json_paths+=("$(ret_json_attribute "streamfile" "${ALSA_PATHS_STREAMFILES[${idx}]}")")
    json_paths+=("$(ret_json_attribute "chardev" "${ALSA_PATHS_CHARDEVS[${idx}]}")")
    json_paths+=("$(ret_json_attribute "monitorfile" "${ALSA_PATHS_MONITORFILES[${idx}]}")")
    json_paths+=("$(ret_json_attribute "statusfile" "${ALSA_PATHS_STATUSFILES[${idx}]}")")
    ret_json_group "paths" "object" "${json_paths[@]}"
}

function ret_json_output() {
    ## returns an unnamed json object with general attributes for the audio output with idx $1.
    idx="$1"
    ## skip empty last item
    [[ ${idx} ]] || return
    declare -a json_output=()
    json_output+=("$(ret_json_attribute "output_id" "${ALSA_IDS_DEVS[${idx}]}")")
    json_output+=("$(ret_json_attribute "name" "${ALSA_NAMES_DEVS[${idx}]}")")
    json_output+=("$(ret_json_attribute "label" "${ALSA_LABELS_DEVS[${idx}]}")")
    json_output+=("$(ret_json_attribute "hwaddress" "hw:${ALSA_CARDDEVS[${idx}]}")")
    json_output+=("$(ret_json_attribute "hwaddress_alt" "hw:${ALSA_NAMES_CARDS[${idx}]},${ALSA_IDS_DEVS[${idx}]}")")
    json_output+=("$(ret_json_attribute "devicetype" "${ALSA_DEVTYPES[${idx}]}")")
    json_output+=("$(ret_json_attribute "uacclass" "${ALSA_UACTYPES[${idx}]}")")
    json_output+=("$(ret_json_paths "${idx}")")
    json_output+=("$(ret_json_formats "${idx}")")
    ret_json_group "" "object" "${json_output[@]}"
}

function ret_json_outputs() {
    ## returns a json array named 'outputs', each item representing an audio output.
    ## $1 should contain a comma separated list of indice.
    IFS="," read -r -a output_idxs <<< "$1"
    debug "${LINENO}" "$(declare -p output_idxs)"
    declare -a json_outputs=()
    for output_idx in "${output_idxs[@]}"; do
        json_outputs+=("$(ret_json_output "${output_idx}")")
    done
    ret_json_group "outputs" "array" "${json_outputs[@]}"
}

function ret_json_card() {
    ## returns an unnamed json object with attributes for a card.
    idx="$1"
    declare -a json_card=() 
    json_card+=("$(ret_json_attribute "card_id" "${ALSA_IDS_CARDS[${idx}]}")")
    json_card+=("$(ret_json_attribute "name" "${ALSA_NAMES_CARDS[${idx}]}")")
    json_card+=("$(ret_json_attribute "label" "${ALSA_LABELS_CARDS[${idx}]}")")
    ## iterate the audio outputs for this card
    json_card+=("$(ret_json_outputs "${cards[${idx}]}")")
    ret_json_group "" "object" "$(json_nest "${json_card[@]}")"
}

function ret_json_cards() {
    ## returns a json array named 'cards', each item representing a card.
    ## because cards and outputs are stored in flat lists, first store
    ## comma separated audio outputs for each card, (re)using the array
    ## index so we have a list of outputs per unique card.
    declare -a cards=() 
    for idx in "${FILTERED_INDICE[@]}"; do
        cards["${ALSA_IDS_CARDS[${idx}]}"]+="${idx},"
    done
    debug "${LINENO}" "$(declare -p cards)"
    declare -a json_cards=()
    for idx in "${!cards[@]}"; do
        json_cards+=("$(ret_json_card "${idx}")")
    done
    ret_json_group "cards" "array" "$(json_nest "${json_cards[@]}")"
}

function do_output_json() {
    ## print json formatted output to std_out.
    ## called by fetch_alsa_outputinterfaces.
    ret_json_group "" "object" "$(ret_json_cards)"
}


function do_output_terminal() {
    counter=0
    for idx in "${FILTERED_INDICE[@]}"; do
        ((counter++))
        case "${ALSA_DEVTYPES["${idx}"]}" in
            "${DEVTYPE_UAC}") c_dev="${c_green}" ;;
            "${DEVTYPE_DIGITAL}") c_dev="${c_blue}" ;;
            "${DEVTYPE_ANALOG}") c_dev="${c_yellow}" ;;
        esac
        s_counter="${c_bold}${c_dim}${counter}:${c_std}"
        s_title="${c_dev}\`${c_bold}${ALSA_NAMES_DEVS["${idx}"]}${c_std}${c_dev}' ${c_dev}${ALSA_DEVTYPES["${idx}"]} audio output ${c_dev}on device ${c_bold}${ALSA_LABELS_CARDS["${idx}"]}${c_std}"
        printf -v l_hwaddress "${c_dim}%-32s${c_std}" "-hardware address:"
        printf -v l_cardlabel "${c_dim}%-32s${c_std}" "-device label:"
        printf -v l_path_char "${c_dim}%-32s${c_std}" "-character device:"
        printf -v l_path_mntr "${c_dim}%-32s${c_std}" "-monitor file:"
        ## TODO formats
        printf -v l__uacclass "${c_dim}%-32s${c_std}" "-usb audio class:"
        printf -v l_path_strf "${c_dim}%-32s${c_std}" "-streamfile:"
        if [[ ${OPT_SAMPLERATES} ]]; then 
            printf -v l_samplerts "${c_dim}%-32s${c_std}" "-sample rates per format:"
        else
            printf -v l_samplerts "${c_dim}%-32s${c_std}" "-formats:"
        fi

        v_hwaddress="${c_bold}hw:${ALSA_CARDDEVS["${idx}"]}${c_std}"
        v_hwaddress+=" ${c_dim} (or ${c_bold}hw:${ALSA_NAMES_CARDS["${idx}"]},${ALSA_IDS_DEVS["${idx}"]}${c_std}${c_dim})${c_std}"
        v_cardlabel="${c_bold}${ALSA_LABELS_CARDS["${idx}"]}${c_std}"
        v_formats="${ALSA_FORMATS["${idx}"]}"
        [[ "${v_formats}" =~ ${MSG_ERROR_GETTINGFORMATS} ]] || \
            v_formats="${c_bold}${v_formats}${c_std}"
        details="\
${s_counter} ${s_title}
    ${l_hwaddress} ${v_hwaddress}
    ${l_cardlabel} ${v_cardlabel}
    ${l_samplerts} ${v_formats}
    ${l__uacclass} ${c_bold}${ALSA_UACTYPES["${idx}"]}${c_std}
    ${l_path_strf} ${c_bold}${ALSA_PATHS_STREAMFILES["${idx}"]}${c_std}
    ${l_path_char} ${c_bold}${ALSA_PATHS_CHARDEVS["${idx}"]}${c_std}
    ${l_path_mntr} ${c_bold}${ALSA_PATHS_MONITORFILES["${idx}"]}${c_std}
"
        printf "%s" "${details}"
    done
}

### main functions
function get_locking_process() {
    ## return a string describing the command and id of the
    ## process locking the audio output based on its status file.
    ## returns a comma separated string containing the locking cmd and
    ## pid, or an error when the interface is not locked (ie
    ## 'closed').
    idx="$1"
    owner_pid=
    owner_stat=
    owner_cmd=
    parent_pid=
    parent_cmd=
    locking_pid=
    ## specific for mpd: each alsa output plugin results in a locking
    ## process indicated by `owner_pid` in
    ## /proc/asound/cardX/pcmYp/sub0/status: `owner_pid   : 28022'
    ## this is a child process of the mpd parent process (`28017'):
    ##mpd(28017,mpd)-+-{decoder:flac}(28021)
    ##               |-{io}(28019)
    ##               |-{output:Peachtre}(28022) <<< owner_pid / child
    ##               `-{player}(28020)
    owner_pid_re="owner_pid[[:space:]]+:[[:space:]]+([0-9]+)"
    debug "${LINENO}" \
          "examining status file ${ALSA_PATHS_STATUSFILES[${idx}]}." 
    while read -r line; do
	if [[ "${line}" =~ ${owner_pid_re} ]]; then
	    owner_pid="${BASH_REMATCH[1]}"
            debug "${LINENO}" \
                  "device is in use by owner_pid=\`${owner_pid}'" 
	    break
	elif [[ "${line}" == "closed" ]]; then
            debug "${LINENO}" \
                  "${ALSA_PATHS_STATUSFILES[${idx}]}: not in use"
	    return 1
	fi
    done < "${ALSA_PATHS_STATUSFILES[${idx}]}"
    ## check if owner_pid is a child
    ## construct regexp for getting the ppid from /proc
    ## eg: /proc/837/stat:
    ## 837 (output:Pink Fau) S 1 406 406 0 -1 ...
    ## ^^^                       ^^^
    ## +++-> owner_pid           +++-> parent_pid
    parent_pid_re="(${owner_pid}) \(.*\) [A-Z] [0-9]+ ([0-9]+)"
    read -r owner_stat < "/proc/${owner_pid}/stat"
    debug "${LINENO}" "check if owner_pid is a child; owner_stat: \`${owner_stat}'"
    if [[ "${owner_stat}" =~ ${parent_pid_re} ]]; then
	parent_pid="${BASH_REMATCH[2]}"
	if [[ "x${parent_pid}" == "x${owner_pid}" ]]; then
	    ## device is locked by the process with id owner_pid, look
	    ## up command eg: /proc/837/cmdline:
            ## /usr/bin/mpd --no-daemon /var/lib/mpd/mpd.conf
	    read -r owner_cmd < "/proc/${owner_pid}/cmdline"
	    debug "${LINENO}" \
                  "cmd=\`${owner_cmd}' with ownerpid=\`${owner_pid}' has no parent."
	    locking_pid="${owner_pid}"
	else
	    ## device is locked by the parent of the process with owner_pid
	    read -r owner_cmd < "/proc/${owner_pid}/cmdline"
	    # shellcheck disable=SC2162	    
	    read -r parent_cmd < "/proc/${parent_pid}/cmdline"
	    debug "${LINENO}" \
                  "cmd=\`${owner_cmd}' with ownerpid=\`${owner_pid}' \
has parent cmd=\`${parent_cmd}' with ownerpid=\`${parent_pid}'."
	    locking_pid="${parent_pid}"
	    #locking_cmd="${parent_cmd}"
	fi
	## return comma separated list (pid,cmd) to calling function
        declare -a locking_cmdline=()
        # shellcheck disable=SC2162
	while read -d $'\0' line; do
            locking_cmdline+=("${line}")
            debug "${LINENO}" "$(declare -p line)"
        done < "/proc/${locking_pid}/cmdline"
	#printf "%s,%s" "${locking_pid}" "${locking_cmd%% }"
        debug "${LINENO}" "$(declare -p locking_cmdline)"
        printf "${c_dim}(%s by \`%s %s' with PID %s).${c_std}\n" \
               "${MSG_ERROR_GETTINGFORMATS}" \
	       "${locking_cmdline[0]}" \
               "${locking_cmdline[@]:1}" \
               "${locking_pid}" 
        return 0
    fi 
}


function check_samplerate() {
    ## use aplay to check if the specified alsa interface ($1)
    ## supports encoding format $2 and sample rate $3
    ## returns a string with the supported sample rate or nothing
    idx="$1"
    format="$2"
    samplerate="$3"
    declare -a aplay_args=(
        "--device=hw:${ALSA_CARDDEVS[${idx}]}"
        "--format=${format}"
        "--channels=2"
        "--nonblock"
        "--rate=${samplerate}"
    )
    debug "${LINENO}" "hw:${ALSA_CARDDEVS[${idx}]} @ ${format} @ ${samplerate}"
    playing_re=".*Playing raw data.*"
    while read -r aplayline; do
        debug "${LINENO}" "aplayline=\`${aplayline}'"
        if [[ "${aplayline}" =~ ${playing_re} ]]; then
            printf "%s" "${samplerate}"
            return 0
        fi
    done <<< "$(
        LANG=C aplay "${aplay_args[@]}" 2>&1 <<< /dev/zero || \
            debug "${LINENO}" "evaluating aplay error feedback."
    )"
}


function ret_highest_alsa_samplerate() {
    ## check the highest supported rate of type $3 for format $2 on
    ## interface $1
    ## returns the highest supported rate.
    idx="$1"
    format="$2"
    type="$3"
    debug "${LINENO}" "checking hwaddress=\`hw:${ALSA_CARDDEVS[${idx}]}' with encoding format \`${format}' of type \`${type}'"
    declare -a rates=()
    if [[ "${type}" == "audio" ]]; then
	read -r -a rates <<< "${SAMPLERATES_AUDIO[@]}"
    else
	read -r -a rates <<< "${SAMPLERATES_VIDEO[@]}"
    fi
    for rate in "${rates[@]}"; do
	check_samplerate "${idx}" "${format}" "${rate}" && return 0
    done
}


function rates_for_format() {
    ## use aplay to get supported sample rates for playback for
    ## specified non-uac interface ($1) and encoding format ($2).
    ## returns a space separated list of valid rates.
    idx="$1"
    format="$2"
    declare -a rates
    debug "${LINENO}" "getting samplerates for \`hw:${ALSA_CARDDEVS[${idx}]}' \
using encoding_format \`${format}'."
    ## check all audio/video rates from high to low; break when rate is
    ## supported while adding all the lower frequencies
    highest_audiorate="$(ret_highest_alsa_samplerate \
"${idx}" "${format}" "audio")"
    highest_videorate="$(ret_highest_alsa_samplerate \
"${idx}" "${format}" "video")"
    ## when supported assume all lower rates are supported too
    for rate in "${SAMPLERATES_AUDIO[@]}"; do
	(( rate <= highest_audiorate )) && rates+=("${rate}")
    done
    for rate in "${SAMPLERATES_VIDEO[@]}"; do
	(( rate <= highest_videorate )) && rates+=("${rate}")
    done
    debug "${LINENO}" "$(declare -p rates)"
    ## sort and return the newline separated sample rates
    #shellcheck disable=SC2207
    IFS=$'\n' sorted=($(sort -r -n <<<"${rates[*]}"))
    unset IFS
    printf "%s " "${sorted[@]}"
}


function get_nonuac_formats_rates() {
    ## force aplay to output error message containing supported
    ## encoding formats, by playing /dev/zero in a non-existing
    ## format (=200 times faster than --dump-hw-params)
    idx="$1"
    declare -a aplay_args=(
        "--device=hw:${ALSA_CARDDEVS[${idx}]}"
        "--channels=2"
        "--format=MPEG"
        "--nonblock"
    )
    ## if the device is locked return error (and print string
    ## describing locking command)
    get_locking_process "${idx}" && return 1
    debug "${LINENO}" "device is not locked; will iterate aplay_out"
    declare -a formats_unsorted=()
    format_re="^- +(.*)$"
    ## iterate the aplay error message to get supported formats
    while read -r aplayline; do
        debug "${LINENO}" "aplayline=\`${aplayline}'"
	if [[ "${aplayline}" =~ ${format_re} ]]; then
	    formats_unsorted+=("${BASH_REMATCH[1]}")
	    debug "${LINENO}" "using 1=\`${BASH_REMATCH[1]}' from
$(declare -p BASH_REMATCH)"
	fi
    done< <(
        LANG=C aplay "${aplay_args[@]}" 2>&1 <<< /dev/zero || \
            debug "${LINENO}" "iterate aplay error feedback." 
    )
    debug "${LINENO}" "$(declare -p formats_unsorted)"
    ## formats (and minimum/maximum sample rates) gathered, check if
    ## all sample rates should be checked
    if [[ ${OPT_SAMPLERATES} ]]; then
	## check all sample rates for each format.  warning:
	## slowness ahead, because of an aplay call for each
	## sample rate higher than supported  + 1 for each format.
        ## returns newline separated lines (FORMAT: RATE1, RATE2).
        declare -a formats_rates=()
        for format in "${formats_unsorted[@]}"; do
            debug "${LINENO}" "getting samplerates for format=\`${format}'"
            read -r -a samplerates < <(
                 rates_for_format "${idx}" "${format}"
            )
            printf -v str_rates "%s, " "${samplerates[@]}"
            formats_rates+=("${format}: ${str_rates%*, }")
            debug "${LINENO}" "samplerates array for format=\`${format}':
$(declare -p samplerates)
format=\`${format}': rates=\`${str_rates%*, }'"
        done
        debug "${LINENO}" "$(declare -p formats_rates)"
        printf "%s\n" "${formats_rates[@]}"
    else
        ## no samplerates requested; just return the comma separated
        ## format(s)
	printf -v str_formats "%s, " "${formats_unsorted[@]}"
	printf "%-20s\n" "${str_formats%*, }"
    fi
}

function get_uac_formats_rates() {
    ## get encodings formats with samplerates for uac type interface
    ## using its streamfile $1 (which saves calls to applay).
    ## returns newline separated list (FORMAT:RATE,RATE,...).
    idx="$1"
    interface_re="^[[:space:]]*Interface ([0-9])"
    format_re="^[[:space:]]*Format: (.*)"
    rates_re="^[[:space:]]*Rates: (.*)"
    capture_re="^Capture:"
    inside_interface=
    format_found=
    declare -A uac_formats
    ## iterate lines in the streamfile
    while read -r line; do
        ## end of playback interfaces
	[[ "${line}" =~ ${capture_re} ]] && 
	    break
	## new interface found
	    ## reset (previous) format_found
	if [[ "${line}" =~ ${interface_re} ]]; then
	    inside_interface=true
	    format_found=
	else
	    ## continuation of interface 
	    [[ ${inside_interface} ]] || break
	    ## parse lines below `Interface:`
	    if [[ ${format_found} ]]; then
		## parse lines below `Format:`
		if [[ "${line}" =~ ${rates_re} ]]; then
		    ## sample rates for interface/format found;
		    ## fill array item with samplerates and reset tests
		    uac_formats["${format_found}"]="${BASH_REMATCH[1]}"
		    debug "${LINENO}" "rates=\`${BASH_REMATCH[1]}'"
		    format_found=
		    inside_interface=
		fi
            else
		## format found, set array item key
		[[ "${line}" =~ ${format_re} ]] && format_found="${BASH_REMATCH[1]}"
	    fi
	fi
    done < "${ALSA_PATHS_STREAMFILES[${idx}]}"
    if [[ ${OPT_SAMPLERATES} ]]; then
        for format in "${!uac_formats[@]}"; do
            printf "%s: %s\n" "${format}" "${uac_formats[${format}]}"
        done
    else
        ## only use keys; comma separate them
        printf -v str_formats "%s, " "${!uac_formats[@]}"
        printf "%-20s" "${str_formats%*, }"
    fi
}


function get_formats_rates() {
    ## simple function to select the proper function for uac/non-uac outputs
    idx="$1"
    if [[ "${ALSA_UACTYPES[${idx}]}" == "${MSG_PROP_NOTAPPLICABLE}" ]] ; then
        get_nonuac_formats_rates "${idx}"
    else
        get_uac_formats_rates "${idx}"
    fi
}

function alsa_uac_endpoint() {
    ## returns the usb audio class endpoint as a fixed number.
    ## needs path to stream file as single argument ($1)
    ## based on ./sound/usb/proc.c:
    ##  printf "    Endpoint: %d %s (%s)\n",
    ##   1: fp->endpoint & USB_ENDPOINT_NUMBER_MASK (0x0f) > [0-9]
    ## TODO: unsure which range this is; have seen 1, 3 and 5
    ##       or 0, 1, 2 or 3 according to ./sound/usb/card.h
    ##   2: USB_DIR_IN: "IN|OUT",
    ##   3: USB_ENDPOINT_SYNCTYPE: "NONE|ASYNC|ADAPTIVE|SYNC"
    streamfile="$1"
    endpoint_type=""
    ## match 1 using keys of UAC_ENDPOINT_TYPES
    printf -v synctypes "%s|" "${!UAC_ENDPOINT_TYPES[@]}"
    ep_re="^[[:space:]]*Endpoint: ([0-9]+) OUT \((${synctypes%*|})\)"
    ## iterate the contents of the streamfile
    while read -r line; do
	if [[ "${line}" =~ ${ep_re} ]]; then
            endpoint_type="${UAC_ENDPOINT_TYPES[${BASH_REMATCH[2]}]}"
            debug "${LINENO}" "UAC endpoint found: $(declare -p BASH_REMATCH)"
            break
        fi
    done<"${streamfile}"
    [[ ${endpoint_type} ]] || 
	    die "unable to determine UAC Endpoint type from streamfile using regexp \`${ep_re}'. 
streamfile: \`${streamfile}'
$(cat "${streamfile}")"
    echo "${endpoint_type}"
}


function after_filtering() {
    ## actions on main arrays which are more expensive and therefore
    ## are performed after filtering by using outputs in FILTERED_INDICE.
    [[ ${OPT_SAMPLERATES} ]] && alsa_mute
    for idx in "${FILTERED_INDICE[@]}"; do
        [[ -f "${ALSA_PATHS_STREAMFILES[${idx}]}" ]] && \
            read -r uactype < <(
                alsa_uac_endpoint "${ALSA_PATHS_STREAMFILES[${idx}]}"
            )
        ALSA_UACTYPES["${idx}"]="${uactype:-${MSG_PROP_NOTAPPLICABLE}}"
        declare -a formats_rates_array=()
        if [[ ${TESTFILE} ]]; then
            formats_rates_array=("(no formats: using testfile)")
        else
            while read -r format_rates; do
                formats_rates_array+=("${format_rates}")
            done< <(get_formats_rates "${idx}")
            debug "${LINENO}" "$(declare -p formats_rates_array)"
        fi
        debug "${LINENO}" "$(declare -p formats_rates_array)"
        counter=0
        ALSA_FORMATS["${idx}"]=""
        for format_rate in "${formats_rates_array[@]}"; do
            prefix=""
            ## add spacing for all but the first line
            (( counter > 0 )) && printf -v prefix "
%37s" " "
            ALSA_FORMATS["${idx}"]+="${prefix}${format_rate}"
            ((counter++))
        done
        ALSA_FORMATS["${idx}"]="${ALSA_FORMATS["${idx}"]:-${MSG_PROP_NOTAPPLICABLE}}"
        debug "${LINENO}" "$(declare -p ALSA_FORMATS)"
    done
}

### filtering functions
function filter_evaluate() {
    filtertype="$1"
    filtervalue="$2"
    oricount="$3"
    newcount="$4"
    msg_filtertype="${c_bold}${filtertype}${c_std}"
    msg_filtervalue="'${c_bold}${c_dim}${filtervalue}${c_std}'"
    msg_oricount="${c_bold}${oricount}${c_std}"
    msg_newcount="${c_bold}${newcount}${c_std}"
    if (( newcount == 0 )); then
        # shellcheck disable=SC2059
        printf -v msg "${MSG_FILTER_ERR}\n" \
               "${msg_filtertype}" \
               "${msg_filtervalue}'" \
               "${msg_oricount}"
        die "${msg}"
    elif (( oricount == newcount )); then
        # shellcheck disable=SC2059
        printf 1>&2 "${MSG_FILTER_NOEFFECT}\n" \
                    "${msg_filtertype}" \
                    "${msg_filtervalue}'" \
                    "${msg_oricount}"
    else
        # shellcheck disable=SC2059
        printf 1>&2 "${MSG_FILTER_NOTICE}\n" \
                    "${msg_newcount}" \
                    "${msg_oricount}" \
                    "${msg_filtertype}" \
                    "${msg_filtervalue}"
    fi
}

function apply_filter_hwaddress() {
    ## applies OPT_FILTER_HWADDRESS to FILTERED_INDICE in effect limiting
    ## FILTERED_INDICE (further).
    [[ ${OPT_FILTER_HWADDRESS} ]] || return 0
    oricount="${#FILTERED_INDICE[@]}"
    for idx in "${FILTERED_INDICE[@]}"; do
        debug "${LINENO}" "evaluating OPT_FILTER_HWADDRESS=\`${OPT_FILTER_HWADDRESS}'==\`hw:${ALSA_CARDDEVS["${idx}"]}'"
        if [[ "hw:${ALSA_CARDDEVS["${idx}"]}" == "${OPT_FILTER_HWADDRESS}" ]] || [[ "hw:${ALSA_CARDDEVS["${idx}"]}" == "hw:${OPT_FILTER_HWADDRESS}" ]]; then
            debug "${LINENO}" "match for idx=\`${idx}'"
            FILTERED_INDICE=("${idx}")
            break
        fi
    done
    newcount="${#FILTERED_INDICE[@]}"
    filter_evaluate \
        "hardware address" \
        "${OPT_FILTER_HWADDRESS}" \
        "${oricount}" \
        "${newcount}" || return 1
}

function apply_filter_custom() {
    ## applies OPT_FILTER_CUSTOM to FILTERED_INDICE in effect limiting
    ## FILTERED_INDICE (further).
    [[ ${OPT_FILTER_CUSTOM} ]] || return 0 
    oricount="${#FILTERED_INDICE[@]}"
    for idx in "${FILTERED_INDICE[@]}"; do
        [[ "${ALSA_MATCHSTRINGS["${idx}"]}" =~ ${OPT_FILTER_CUSTOM} ]] || \
            unset FILTERED_INDICE["${idx}"]
    done
    newcount="${#FILTERED_INDICE[@]}"
    filter_evaluate \
        "custom" \
        "${OPT_FILTER_CUSTOM}" \
        "${oricount}" \
        "${newcount}" || return 1
}


function apply_filter_devtype() {
    ## applies OPT_FILTER_DEVTYPE to raw results in effect limiting FILTERED_INDICE.
    [[ ${OPT_FILTER_DEVTYPE} ]] || return 0
    debug "${LINENO}" "applying devtype filter \`${OPT_FILTER_DEVTYPE}'"
    oricount="${#FILTERED_INDICE[@]}"
    for idx in "${FILTERED_INDICE[@]}"; do
        [[ "${ALSA_DEVTYPES["${idx}"]}" == "${OPT_FILTER_DEVTYPE}" ]] || \
            unset FILTERED_INDICE["${idx}"]
    done
    newcount="${#FILTERED_INDICE[@]}"
    filter_evaluate \
        "output type" \
        "${OPT_FILTER_DEVTYPE}" \
        "${oricount}" \
        "${newcount}" || return 1
}


function alsa_carddev_arrays() {
    ## fills ALSA arrays by matching CMD_APLAY output to regexp ALSA_CARDLINE_RE.
    ## returns error on nosoundcardsfound
    while read -r aplayline; do
        if [[ "${aplayline}" == "no soundcards" ]]; then
            return 1
        fi
        if [[ "${aplayline}" =~ ${ALSA_CARDLINE_RE} ]]; then
            cardnr="${BASH_REMATCH[1]}"
            ALSA_IDS_CARDS+=("${cardnr}")
            ALSA_NAMES_CARDS+=("${BASH_REMATCH[2]}")
            ALSA_LABELS_CARDS+=("${BASH_REMATCH[3]}")
            devnr="${BASH_REMATCH[4]}"
            ALSA_IDS_DEVS+=("${devnr}")
            ALSA_NAMES_DEVS+=("${BASH_REMATCH[5]}")
            ALSA_LABELS_DEVS+=("${BASH_REMATCH[6]}")
            ## constructed shortcuts
            ALSA_CARDDEVS+=("${cardnr},${devnr}")
            ALSA_PATHS_HWPARAMS+=("/proc/asound/card${cardnr}/pcm${devnr}p/sub0/hw_params")
            ALSA_PATHS_STATUSFILES+=("/proc/asound/card${cardnr}/pcm${devnr}p/sub0/status")
            ALSA_PATHS_CHARDEVS+=("/dev/snd/pcmC${cardnr}D${devnr}p")
            matchstring="hw:${cardnr},${devnr}"
            matchstring+=" ${BASH_REMATCH[2]} ${BASH_REMATCH[3]}"
            matchstring+=" ${BASH_REMATCH[5]} ${BASH_REMATCH[6]}"
            ALSA_MATCHSTRINGS+=("${matchstring}")
            ALSA_PATHS_MONITORFILES+=("/proc/asound/card${cardnr}/pcm${devnr}p/sub0/hw_params")
            ## set DEVTYPE
            streamfile="/proc/asound/card${cardnr}/stream${devnr}"
            if [[ -f "${streamfile}" ]]; then
                ALSA_PATHS_STREAMFILES+=("${streamfile}")
                devtype="${DEVTYPE_UAC}"
            else
                ALSA_PATHS_STREAMFILES+=("${MSG_PROP_NOTAPPLICABLE}")
                ## construct space separated list of names/labels
                ## CAUTION: this resets original BASH_REMATCH array!
                devtype=""
                for filter in "${DO_FILTER_LIST[@]}"; do
                    if [[ "${matchstring,,}" =~ ${filter} ]]; then
                        devtype="${DEVTYPE_DIGITAL}"
                        break
                    fi
                done
            fi
            ## not digital and not uac = analog
            devtype="${devtype:-${DEVTYPE_ANALOG}}"
            ALSA_DEVTYPES+=("${devtype}")
        fi
    done< <(
        LANG=C ${CMD_APLAYL} 2>&1 || die "error executing \`${CMD_APLAYL}'"
    )
    debug "${LINENO}" "starting with a total of ${#ALSA_IDS_CARDS[@]} audio outputs"
}


function fetch_alsa_interfaces() {
    alsa_carddev_arrays || die "${MSG_ERR_NOSOUNDCARDS}"
    ## fill INDICE with indexes of one of the arrays
    FILTERED_INDICE=("${!ALSA_IDS_CARDS[@]}")
    apply_filter_devtype || return 1
    apply_filter_custom  || return 1
    apply_filter_hwaddress || return 1
    debug "${LINENO}" "results: ${#FILTERED_INDICE[@]} after filtering ${#ALSA_IDS_CARDS[@]} interfaces"
    after_filtering
    if [[ ${OPT_JSON} ]]; then
        do_output_json
    else
        ## output to terminal when OPT_QUIET is not set
        [[ ${OPT_QUIET} ]] || do_output_terminal
    fi
}


function main() {
    ## main function; see display_usageinfo()
    ## check if needed commands are available
    type -p aplay 2>/dev/null 1>&2 || \
	die "${APP_NAME_AC} cannot continue without aplay 
(part of the \`alsa-utils' package on most distributions.)"
    ## if TESTFILE is specified use it instead of `aplay -l'
    [[ -f ${TESTFILE} ]] && CMD_APLAYL="cat '${TESTFILE}'"
    analyze_command_line "$@"
    set_colors
    fetch_alsa_interfaces
    ## exit with error if no matching output line was found
    ## for backwards compatibility
    ALSA_AIF_LABELS=("${ALSA_LABELS_CARDS[@]}")
    ALSA_AIF_DEVNAMES=("${ALSA_NAMES_DEVS[@]}")
    ALSA_AIF_DEVLABELS=("${ALSA_LABELS_DEVS[@]}")
    ALSA_AIF_HWADDRESSES=("$(printf "hw:%s\n" "${ALSA_CARDDEVS[@]}")")
    ALSA_AIF_CHARDEVS=("${ALSA_PATHS_CHARDEVS[@]}")
    ALSA_AIF_MONITORFILES=("${ALSA_PATHS_MONITORFILES[@]}")
    ALSA_AIF_UACCLASSES=("${ALSA_UACTYPES[@]}")
    ALSA_AIF_FORMATS=("${ALSA_FORMATS[@]}")
    ALSA_AIF_DISPLAYTITLES=()
    ## return success if interfaces are found
    return 0
}

### global variables

## static filter for digital outputs
DO_FILTER_LIST=(
    adat
    aes
    ebu
    digital
    dsd
    hdmi
    i2s
    iec958
    spdif
    s/pdif
    toslink
    uac
    usb
)
## construct static list of sample rates based on ground clock
## frequencies of:
##  - video: 24.576  (mHz) * 1000000 / 512 = 48000Hz
##  - audio: 22.5792 (mHz) * 1000000 / 512 = 44100Hz
base_fs_video=$(( 24576000 / 512 ))
base_fs_audio=$(( 22579200 / 512 ))
declare -a SAMPLERATES_AUDIO
declare -a SAMPLERATES_VIDEO
max_fs_n=8
for (( n = max_fs_n; n >= 1; n = n / 2 )); do
    debug "${LINENO}" "n=\`${n}'"
    SAMPLERATES_VIDEO+=("$(( base_fs_video * n ))")
    SAMPLERATES_AUDIO+=("$(( base_fs_audio * n ))")
done
## aplay -l matching: in this script we call soundcards CARD
## (called 'info' in aplay.c), and outputs DEV (called 'pcminfo' in alsa):
## printf(_("card %i: %s [%s], device %i: %s [%s]\n"),
## 1 cardnr, snd_ctl_card_info_get_id(info), snd_ctl_card_info_get_name(info),
## 2 devnr, snd_pcm_info_get_id(pcminfo), snd_pcm_info_get_name(pcminfo));
## CAUTION:
##  ..._info_get_id (='name' in this script) can contain square
##      brackets 'My [Funky] Dev'
##  ..._info_get_name (='label' in this script) is surrounded by
##      square brackets, and van contain square brackets itself ('[My
##      [Funky] Dev]') and van be empty ('[]')
ALSA_CARDLINE_RE="^card ([0-9]+): ([^[]+) \[(.*)\], device ([0-9]+): ([^[]+) \[(.*)\]$"
## arrays for holding the aplay regexp grouping results
## see function alsa_carddev_arrays
declare -a ALSA_IDS_CARDS=()
declare -a ALSA_NAMES_CARDS=()
declare -a ALSA_LABELS_CARDS=()
declare -a ALSA_IDS_DEVS=()
declare -a ALSA_NAMES_DEVS=()
declare -a ALSA_LABELS_DEVS=()

## constructed arrays:
declare -a ALSA_CARDDEVS=()
declare -a ALSA_PATHS_HWPARAMS=()
declare -a ALSA_PATHS_CHARDEVS=()
declare -a ALSA_PATHS_STREAMFILES=()
declare -a ALSA_PATHS_MONITORFILES=()
declare -a ALSA_PATHS_STATUSFILES=()
declare -a ALSA_DEVTYPES=()
declare -a ALSA_UACTYPES=()
declare -a ALSA_MATCHSTRINGS=()
declare -a ALSA_FORMATS=()
## for backwards compatibility
# shellcheck disable=SC2034
declare -a ALSA_AIF_LABELS=()
# shellcheck disable=SC2034
declare -a ALSA_AIF_DEVNAMES=()
# shellcheck disable=SC2034
declare -a ALSA_AIF_DEVLABELS=()
# shellcheck disable=SC2034
declare -a ALSA_AIF_HWADDRESSES=()
# shellcheck disable=SC2034
declare -a ALSA_AIF_CHARDEVS=()
# shellcheck disable=SC2034
declare -a ALSA_AIF_MONITORFILES=()
# shellcheck disable=SC2034
declare -a ALSA_AIF_UACCLASSES=()
# shellcheck disable=SC2034
declare -a ALSA_AIF_FORMATS=()
# shellcheck disable=SC2034
declare -a ALSA_AIF_DISPLAYTITLES=()

## for filtering
declare -a FILTERED_INDICE=()
## for (un)muting, storing alsactl state.file 
ALSA_STATEFILE="${ALSA_STATEFILE:-}"
## DEVTYPES
DEVTYPE_UAC="Digital USB Audio Class"
DEVTYPE_DIGITAL="Digital non-UAC"
DEVTYPE_ANALOG="Analog"
CMD_APLAYL="aplay -l"
## USB_SYNC_TYPEs
## strings alsa uses for UAC endpoint descriptors.
## one of *sync_types "NONE", "ASYNC", "ADAPTIVE" or "SYNC" according
## to ./sound/usb/proc.c
declare -A UAC_ENDPOINT_TYPES
UAC_ENDPOINT_TYPES[NONE]="0 - none"
UAC_ENDPOINT_TYPES[ADAPTIVE]="UAC1 (isochronous adaptive)"
UAC_ENDPOINT_TYPES[ASYNC]="UAC2 (isochronous asynchronous)"
UAC_ENDPOINT_TYPES[SYNC]="UAC3 (unknown)"
## labels for UAC classes.
## system messages
MSG_PROP_NOTAPPLICABLE="(n/a)"
MSG_ERROR_GETTINGFORMATS="can't detect: output is in use"
MSG_ERR_NOSOUNDCARDS="aplay did not find any soundcard."
#MSG_FILTER_ERR="Filter error"
MSG_FILTER_NOTICE="Listing %s of the total %s audio outputs that matches your %s filter: %s"
MSG_FILTER_NOEFFECT="The %s-filter %s matches all of the %s audio outputs (it's too loose)."
MSG_FILTER_ERR="The %s-filter %s matched none of the %s audio outputs (it's too restrictive)."

## command line options
OPT_QUIET=${OPT_QUIET:-}
OPT_JSON=${OPT_JSON:-}
OPT_FILTER_CUSTOM=${OPT_FILTER_CUSTOM:-}
OPT_FILTER_HWADDRESS=${OPT_FILTER_HWADDRESS:-}
OPT_FILTER_DEVTYPE=${OPT_FILTER_DEVTYPE:-}
OPT_SAMPLERATES=${OPT_SAMPLERATES:-}
OPT_NOCOLOR=${OPT_NOCOLOR:-}
OPT_SOURCED=""

## output formatting
c_bold=""
c_dim=""
c_std=""
c_red=""
c_green=""
c_yellow=""
c_blue=""
c_white=""

trap cleanup EXIT

## if the script is not sourced by another script but run within its
## own shell call function `main'
if [[ "${BASH_SOURCE[0]:-}" != "${0}" ]]; then
    OPT_SOURCED=true
    printf 1>&2 "%s sourced.\n" "${0}"
else
    main "$@"
fi