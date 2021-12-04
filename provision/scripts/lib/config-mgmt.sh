#!/usr/bin/env bash

set -eo pipefail

# Copy Config File From Template and Wait for Confirmation
function generate_confirm_config_file(){
  local template_file=$1
  local config_file=$2
  if [ ! -f $config_file ]; then
    cp "$template_file" "$config_file"
    echo -e " ${BOLD}${BLUE}Edit ${UNDERLINE}$config_file ${NC}\n"
    confirm 
  else
    echo -e " ${ORANGE}Reusing Existing $config_file ${NC} Config Files\n"
  fi 
}

# Add Config File and Wait for Confirmation
function add_confirm_config_file(){
  local config_file=$1
  if [ ! -f $config_file ]; then
    echo -e " ${BOLD}${BLUE}Add ${UNDERLINE}$config_file ${NC}\n"
    confirm 
  else
    echo -e " ${ORANGE}Reusing Existing $config_file ${NC} Config Files\n"
  fi 
}

# Generate & Check for Configuration Files
function generate_pre_vm_config_files(){

  echo -e "\n${BOLD}${UNDERLINE}🧪 Prerequisites Checks...${NC}\n"
  exit_on_pre_condition_checks

  # VMs 
  local vms_list_template_file="config/templates/vms.list"
  local vms_list_config_file="config/generated/pre-vm-creation/vms.list"
  generate_confirm_config_file "$vms_list_template_file" "$vms_list_config_file"

  # Apps
  local apps_list_template_file="config/templates/vms.list"
  local apps_list_config_file="config/generated/pre-vm-creation/vms.list"
  generate_confirm_config_file "$apps_list_template_file" "$apps_list_config_file"

  # Add .vault_password file for MMonit
  echo -e "${BOLD}${UNDERLINE}Checking for Prerequisites Configuration Files ${NC}"
  local vault_password_file="config/generated/post-vm-creation/.vault_password"
  add_confirm_config_file "$vault_password_file"

  # scripts/lib/ssh.sh
  generate_ssh_key
  create_cloud_init_config_from_template


  # User Mgmt 
  local duo_template_file="config/templates/duo.env.sample"
  local duo_config_file="config/generated/post-vm-creation/duo.env"
  generate_confirm_config_file "$duo_template_file" "$duo_config_file"

  local SSH_PUBLIC_KEY="config/generated/pre-vm-creation/id_rsa.pub"
  file_replace_text "_CEC_USER_.*$" "${USER}" "${duo_config_file}"
  file_replace_text "_SSH_KEY_.*$" "$(cat $SSH_PUBLIC_KEY)" "${duo_config_file}"
  source "$duo_config_file"

}

# Clean Configuration File
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