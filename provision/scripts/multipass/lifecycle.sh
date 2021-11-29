#!/usr/bin/env bash

set -eo pipefail

CONFIG_TEMPLATE_PATH="config/templates"

function generate_vm_provisioning_command(){
  local CPU=${CPU:-"2"}
  local MEMORY=${MEMORY:-"2G"}
  local DISK=${DISK:-"4G"}
  local CLOUD_INIT_FILE="$CONFIG_PATH/cloud-init.yaml"

  VM_NAME=$1
  CMD="multipass launch --name $VM_NAME --cpus $CPU --mem $MEMORY --disk $DISK --cloud-init $CLOUD_INIT_FILE"
  if [ "$(multipass list | grep -c $VM_NAME )" -eq "1" ]; then
    echo "${ORANGE}${BOLD} $VM_NAME Exists. Skipping command Generation...${NC}"
  else
    echo "$CMD" >> "$CONFIG_PATH/vms.sh"
  fi
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

function stop_delete_vms(){
  local CONFIG_PATH="config/generated/pre-vm-creation"
  while read -r vm
  do
    if [[ ! -z $vm ]]
    then
        if [ $(multipass list | grep -c $vm ) -eq "1" ]; then
          echo "${BOLD}Cleaning $vm${NC}"
          multipass stop $vm || echo "$vm Already Stopped"
          multipass delete $vm || echo "$vm Already Deleted"
          echo "${BOLD}${GREEN}Cleaning $vm Done! ${NC}"
        fi 
    fi
  done < $CONFIG_PATH/vms.list
  multipass purge
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
      config/generated/post-vm-creation/.vault_password \
      config/generated/post-vm-creation/vm.state 
}

function teardown(){
    local MLIST=$(multipass ls)
    if [[ $MLIST == *"No instances"* ]]; then
      echo "All Clean"
    else 
      stop_delete_vms
    fi
}

function shell_to_control_center(){
  VM="control-center"
  if [ $(multipass list | grep Running | grep -c control-center) -eq "1" ]; then 
    multipass shell $VM
  else
    echo "${RED}${BOLD} VM $VM Not Abailable ${NC}" 
  fi
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

function generate_inventory_file(){
  local CONFIG_PATH="config/generated/pre-vm-creation"
  local INVENTORY_PATH="config/generated/post-vm-creation/inventory"
  local USER="ubuntu"
  while read -r vm
  do
    if [[ ! -z $vm ]]
    then
      GROUP_VARS="ansible_ssh_user=$USER ansible_ssh_private_key_file=/home/$USER/.ssh/id_rsa"
      INVENTORY="$(multipass list | grep $vm | grep Running | awk '{print $1 " ansible_ssh_host="$3}')" 
      echo "$INVENTORY $GROUP_VARS" >> $INVENTORY_PATH
    fi
  done < $CONFIG_PATH/vms.list
  echo "${BOLD}${GREEN}Inventory $INVENTORY_PATH Gnereration Done !${NC}"
}

function generate_post_vm_config_files(){
  local CONFIG_PATH="config/generated/post-vm-creation"
  local INVENTORY_PATH="$CONFIG_PATH/inventory"
  cp $CONFIG_TEMPLATE_PATH/inventory.hosts $INVENTORY_PATH
  IP=$(multipass info "$VM_NAME" | grep IPv4 | awk '{print $2}')
  OCTET=$(echo $IP | awk -F '.' '{ print $1}')
  create_ssh_config_from_template $OCTET
  generate_inventory_file
}

function display_apps_status(){
  if [ -f $CONFIG_PATH/apps.list  ];then
      while read -r app
      do
        if [[ ! -z $app ]]
        then
          display_url_status $app
        fi
      done < $CONFIG_PATH/apps.list
  fi 
}

function exit_on_pre_condition_checks(){
  check "multipass" multipass --version 
  check "docker" docker --version 
  reportResults
}

function run_prepare(){
    echo -e "\n${BOLD}${UNDERLINE}🧪 Prerequisites Checks...${NC}\n"
    exit_on_pre_condition_checks
    generate_pre_vm_config_files
    echo -e "\n ${BOLD}${BLUE}Edit ${UNDERLINE}config/generated/pre-vm-creation/vms.list${NC} (optional)\n${NC}"
    confirm
}

