#!/usr/bin/env bash

set -eo pipefail

CONFIG_TEMPLATE_PATH="config/templates"

function run_prepare(){
    echo -e "\n${BOLD}${UNDERLINE}🧪 Prerequisites Checks...${NC}\n"
    exit_on_pre_condition_checks
    generate_pre_vm_config_files
    echo -e "\n ${BOLD}${BLUE}Edit ${UNDERLINE}config/generated/pre-vm-creation/vms.list${NC} (optional)\n${NC}"
}


function create_vm_provisioning_commands(){
  local CONFIG_PATH="config/generated/pre-vm-creation"
  echo "echo "" " > "$CONFIG_PATH/vms.sh"
  while read -r vm
  do
    if [[ ! -z $vm  ]]
    then
      generate_vm_provisioning_command $vm
    fi
  done < $CONFIG_PATH/vms.list
  echo "${GREEN}Provisioning $CONFIG_PATH/vms.sh Done !${NC}"
}

function provision_vms(){
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

function generate_pre_vm_config_files(){
  local CONFIG_PATH="config/generated/pre-vm-creation"
  cp $CONFIG_TEMPLATE_PATH/vms.list $CONFIG_PATH/vms.list
  cp $CONFIG_TEMPLATE_PATH/apps.list $CONFIG_PATH/apps.list
  # scripts/lib/ssh.sh
  generate_ssh_key
  create_cloud_init_config_from_template
  create_user_mgmt_playbook
}

function teardown(){
    local MLIST=$(multipass ls)
    if [[ $MLIST == *"No instances"* ]]; then
      echo "All Clean"
    else 
      stop_delete_vms
    fi
}

function clean_generated_config_files(){
    rm -fr \
      config/generated/pre-vm-creation/id_rsa \
      config/generated/pre-vm-creation/id_rsa.pub \
      config/generated/pre-vm-creation/ssh-config \
      config/generated/pre-vm-creation/cloud-init.yaml \
      config/generated/pre-vm-creation/user-mgmt-playbook.yml \
      config/generated/pre-vm-creation/vms.sh \
      config/generated/pre-vm-creation/vms.list \
      config/generated/pre-vm-creation/apps.list \
      config/generated/post-vm-creation/inventory \
      config/generated/post-vm-creation/ssh-config \
      config/generated/post-vm-creation/vm.state 
}