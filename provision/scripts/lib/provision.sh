#!/usr/bin/env bash

set -eo pipefail

# Provision VMs using generated vms.sh
function provision_vms_from_script(){
  local CONFIG_PATH="config/generated/pre-vm-creation"
  echo -e "\n${BOLD}Starting VMs Provisioning For ${NC}"
  echo "${GRAY}$(cat "$CONFIG_PATH/vms.list")${NC}"
  if ! [ -x "$(command -v parallel)" ]; then
    . "$CONFIG_PATH/vms.sh"
  else
    parallel < "$CONFIG_PATH/vms.sh"
  fi
  local state_file="config/generated/post-vm-creation/vm.state"
  log_state ".vms.provision=done"
  echo -e "\n${BOLD}${GREEN}Provisioning Done !\n${NC}"
}
