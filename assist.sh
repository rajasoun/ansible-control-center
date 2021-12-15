#!/usr/bin/env bash

set -eo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=provision/scripts/load.sh
source "$SCRIPT_DIR/provision/scripts/load.sh"

function help(){
    echo "Usage: $0  {local | openstack }" >&2
    echo
    echo "   local      -> Manage multipass Sandbox Environment via Multipass "
    echo "   configure  -> Ansible Based Configuration "
    echo "   wrapper    -> Wrapper for ansible,openstack and aws "
    echo "   login      -> Login to VM <vm_name> <user>"
    echo
    return 1
}

function ci(){
    if [[ -t 0 ]]; then IT+=(-i); fi
    if [[ -t 1 ]]; then IT+=(-t); fi
    _docker run --rm "${IT[@]}" \   
        --name ci-shell \
        --hostname ci-shell 
        -v "$(pwd):$(pwd)" \
        -v /var/run/docker.sock:/var/run/docker.sock  \
        -w "$(pwd)"  \
        rajasoun/ci-shell:latest
}

opt="$1"
choice=$( tr '[:upper:]' '[:lower:]' <<<"$opt" )
case $choice in
    ci) ci ;;
    local)
        is_vm && raise_error "local can't be run on VM"
        is_connected_to_vpn  && raise_error "Disconnect From VPN.Exiting..."
        multipass_manager "$@" ;;
    configure) ansible_manager   "$@" ;;
    wrapper) wrapper_manager   "$@" ;;
    login) ssh-login "$@" ;;
    *)  help ;;
esac
