#!/usr/bin/env bash

set -eo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=provision/scripts/load.sh
source "$SCRIPT_DIR/provision/scripts/load.sh"

function help(){
    echo "Usage: $0  {multipass | ansible}" >&2
    echo
    echo "   multipass  -> Manage multipass Sandbox Environment "
    echo "   ansible    -> Ansible Docker Runner "
    echo
    return 1
}

opt="$1"
choice=$( tr '[:upper:]' '[:lower:]' <<<"$opt" )
case $choice in
    multipass) multipass_manager "$@" ;;
      ansible) ansible_manager    "$@" ;;
    *)  help ;;
esac

