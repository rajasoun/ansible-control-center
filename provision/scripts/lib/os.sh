#!/usr/bin/env bash

NC=$'\e[0m' # No Color
BOLD=$'\033[1m'
UNDERLINE=$'\033[4m'
RED=$'\e[31m'
GREEN=$'\e[32m'
BLUE=$'\e[34m'
ORANGE=$'\x1B[33m'

FAILED=()

# Returns true (0) if this is an OS X server or false (1) otherwise.
function os_is_darwin {
  [[ $(uname -s) == "Darwin" ]]
}

# Replace a line of text that matches the given regular expression in a file with the given replacement.
# Only works for single-line replacements.
function file_replace_text {
  local -r original_text_regex="$1"
  local -r replacement_text="$2"
  local -r file="$3"

  local args=()
  args+=("-i")

  if os_is_darwin; then
    # OS X requires an extra argument for the -i flag (which we set to empty string) which Linux does no:
    # https://stackoverflow.com/a/2321958/483528
    args+=("")
  fi

  args+=("s|$original_text_regex|$replacement_text|")
  args+=("$file")

  sed "${args[@]}" > /dev/null
}

# Displays Time in misn and seconds
function display_time {
    local T=$1
    local D=$((T/60/60/24))
    local H=$((T/60/60%24))
    local M=$((T/60%60))
    local S=$((T%60))
    (( D > 0 )) && printf '%d days ' $D
    (( H > 0 )) && printf '%d hours ' $H
    (( M > 0 )) && printf '%d minutes ' $M
    (( D > 0 || H > 0 || M > 0 )) && printf 'and '
    printf '%d seconds\n' $S
}

# check pre conditions
function check_pre_conditions(){
    if ! [ -x "$(command -v multipass)" ]; then
        echo 'Error: multipass is not installed.' >&2
        echo 'Goto https://multipass.run/'
        exit 1
    fi
    echo "Pre Condition Checks Passed"
}

# Raise Error
function raise_error(){
  echo -e "${BOLD}${RED}${1}${NC}" >&2
  exit 1
}

# List Functions
function list_functions(){
    bash -c "source $SCRIPT_DIR/load.sh && declare -F" | awk '{ print $3 }'
}

# Display URL Status
function display_url_status(){
    local max_secs_run="2"
    HOST="$1"
    # shellcheck disable=SC1083
    HTTP_STATUS="$(curl -s --max-time "${max_secs_run}" -o /dev/null -L -w ''%{http_code}'' "${HOST}")"
    case $HTTP_STATUS in
      200)  echo "${HOST}  ✅ | Status: $HTTP_STATUS" ;;
      *)    echo "${HOST}  🔴 | Status: $HTTP_STATUS" ;;
    esac
}

function echoStderr(){
    echo "$@" 1>&2
}

function check() {
    app=$1
    shift
    if [ "$(command -v "$@")" ] ; then
        echo "✅  $app check Passed!"
        return 0
    else
        echoStderr "❌ $app check failed."
        FAILED+=("$app")
        return 1
    fi
}

function reportResults() {
    if [ ${#FAILED[@]} -ne 0 ]; then
        echoStderr -e "\n💥  Failed tests:" "${FAILED[@]}"
        return 1
    else
        echo -e "\n${BOLD}${GREEN}All passed!${NC}\n"
        return 0
    fi
}

function is_vm (){
  OS="$(uname)"
  case $OS in
    'Linux')
      # Assume VM if OS is Linux
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

function confirm() {
  local _prompt _default _response

  if [ "$1" ]; then _prompt="$1"; else _prompt="Continue -> "; fi
  _prompt="$_prompt [y/n] ?"

  # Loop forever until the user enters a valid response (Y/N or Yes/No).
  while true; do
    read -r -p "$_prompt " _response
    case "$_response" in
      [Yy][Ee][Ss]|[Yy]) # Yes or Y (case-insensitive).
        return 0
        ;;
      [Nn][Oo]|[Nn])  # No or N.
        return 1
        ;;
      *) # Anything else (including a blank) is invalid.
        ;;
    esac
  done
}

function display_apps_status(){
  APPS_LIST=$1
  if [ -f $APPS_LIST  ];then
      while read -r app
      do
        if [[ ! -z $app ]]
        then
          display_url_status $app
        fi
      done < $APPS_LIST
  fi
}

function is_connected_to_vpn(){
    local max_secs_run="2"
    DEFAULT_HOST="https://www-github.cisco.com"
    HOST="${1:-$DEFAULT_HOST}"
    # shellcheck disable=SC1083
    HTTP_STATUS="$(curl -s --max-time "${max_secs_run}" -o /dev/null -L -w ''%{http_code}'' "${HOST}" )"
    case $HTTP_STATUS in
      200 | 302 )
        echo "VPN - Connected 🔴 | STATUS:$HTTP_STATUS "
        return 0
        ;;
      *)
        echo "VPN - Disconnected  ✅  | STATUS:$HTTP_STATUS"
        return 1
        ;;
    esac
}

# Pretty Table Print
function pretty_table_print {
    column -t -s,  "$@" | less -F -S -X -K
}

# Current Time 
function now {
  NOW=$(now)
  echo ${NOW}
}
