#!/usr/bin/env bash

set -eo pipefail

CONFIG_TEMPLATE_PATH="config/templates"

function check_for_dot_env_files(){
  local vault_password_file="config/generated/post-vm-creation/.vault_password"
  local duo_env_file="config/generated/post-vm-creation/duo.env"
  if [ ! -f $vault_password_file ]; then
    echo -e "${RED}${BOLD} Add $vault_password_file ${NC}"
    confirm 
  fi 
  if [ ! -f $duo_env_file ]; then
    echo -e " ${BOLD}${BLUE}${UNDERLINE}Edit $duo_env_file ${NC}\n"
    confirm 
  fi 
}

function generate_pre_vm_config_files(){
  local CONFIG_PATH="config/generated/pre-vm-creation"
  cp $CONFIG_TEMPLATE_PATH/vms.list $CONFIG_PATH/vms.list
  cp $CONFIG_TEMPLATE_PATH/apps.list $CONFIG_PATH/apps.list
  # scripts/lib/ssh.sh
  generate_ssh_key
  create_cloud_init_config_from_template
}

function run_prepare(){
    echo -e "\n${BOLD}${UNDERLINE}🧪 Prerequisites Checks...${NC}\n"
    exit_on_pre_condition_checks
    generate_pre_vm_config_files
    echo -e "\n ${BOLD}${BLUE}Edit ${UNDERLINE}config/generated/pre-vm-creation/vms.list${NC} \n${NC}"
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
      config/generated/pre-vm-creation/vms.sh \
      config/generated/pre-vm-creation/vms.list \
      config/generated/pre-vm-creation/apps.list \
      config/generated/post-vm-creation/inventory \
      config/generated/post-vm-creation/ssh-config \
      config/generated/post-vm-creation/vm.state \
      config/generated/post-vm-creation/duo.env 
}