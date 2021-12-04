#!/usr/bin/env bash

set -eo pipefail

# Provision VMs using generated vms.sh
function provision_vms_from_script(){
  local CONFIG_PATH="config/generated/pre-vm-creation"
  echo -e "\n${BOLD}Starting VM Creation For ${NC}"
  echo "${GRAY}$(cat "$CONFIG_PATH/vms.list")${NC}"
  if ! [ -x "$(command -v parallel)" ]; then
    . "$CONFIG_PATH/vms.sh"
  else
    parallel < "$CONFIG_PATH/vms.sh"
  fi
  echo "${BOLD}${UNDERLINE}VMs${NC}"
  echo "$(cat $CONFIG_PATH/vms.list)" 
  echo "${BOLD}${GREEN}Provisioning Done !${NC}"
}