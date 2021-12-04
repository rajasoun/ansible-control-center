#!/usr/bin/env bash

set -eo pipefail

CONFIG_TEMPLATE_PATH="config/templates"

# Exit if Precondition Checks Fails for local setup
function exit_on_pre_condition_checks(){
  check "multipass" multipass --version
  check "docker" docker --version
  check "curl" curl --version
  reportResults
}

# Generate VM Provisioning Script from vms.list
function generate_vm_provisioning_scipts(){
  local CONFIG_PATH="config/generated/pre-vm-creation"
  echo "echo "" " > "$CONFIG_PATH/vms.sh"
  while read -r vm
  do
    if [[ ! -z $vm  ]]
    then
      generate_vm_provisioning_command $vm
    fi
  done < $CONFIG_PATH/vms.list
  echo -e "\n${GREEN}Provisioning $CONFIG_PATH/vms.sh Done !${NC}"
}

# Generate VM Provisioning command from multipass
function generate_vm_provisioning_command(){
  local CPU=${CPU:-"2"}
  local MEMORY=${MEMORY:-"2G"}
  local DISK=${DISK:-"4G"}
  local CLOUD_INIT_FILE="$CONFIG_PATH/cloud-init.yaml"

  VM_NAME=$1
  CMD="multipass launch --name $VM_NAME --cpus $CPU --mem $MEMORY --disk $DISK --cloud-init $CLOUD_INIT_FILE"
  if [ "$(multipass list | grep -c $VM_NAME )" -eq "1" ]; then
    echo -e "\n${ORANGE}${BOLD} $VM_NAME Exists. Skipping command Generation...\n${NC}"
  else
    echo "$CMD" >> "$CONFIG_PATH/vms.sh"
  fi
}

# Generate Inventory File from local multipass setup
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
  echo -e "\n${GREEN}Inventory $INVENTORY_PATH Generation Done !\n${NC}"
}

# Generate POST VM Config script for  multipass
function generate_post_vm_config_files(){
  local CONFIG_PATH="config/generated/post-vm-creation"
  local INVENTORY_PATH="$CONFIG_PATH/inventory"
  cp $CONFIG_TEMPLATE_PATH/inventory.hosts $INVENTORY_PATH
  IP=$(multipass info "$VM_NAME" | grep IPv4 | awk '{print $2}')
  OCTET=$(echo $IP | awk -F '.' '{ print $1}')
  generate_ssh_config_from_template "${OCTET}"
  generate_inventory_file
}

# Stop Delete Multipass VMs
function stop_delete_multipass_vms(){
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

# Tear Down Setup
function teardown_multipass_setup(){
    local MLIST=$(multipass ls)
    if [[ $MLIST == *"No instances"* ]]; then
      echo "All Clean"
    else 
      stop_delete_multipass_vms
    fi
}
