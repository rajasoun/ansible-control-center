#!/usr/bin/env bash

set -eo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=provision/scripts/load.sh
source "$SCRIPT_DIR/provision/scripts/load.sh"

function help(){
    echo "Usage: $0  {local | ansible}" >&2
    echo
    echo "   local      -> Manage multipass Sandbox Environment via Multipass "
    echo "   ansible  -> Ansible Based Configuration "
    echo
    return 1
}

opt="$1"
choice=$( tr '[:upper:]' '[:lower:]' <<<"$opt" )
case $choice in
    local) 
        [  check_if_vm ] || raise_error "local can't be run on VM"
        multipass_manager "$@" ;;
    ansible) ansible_manager   "$@" ;;
    *)  help ;;
esac

