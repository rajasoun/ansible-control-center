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

# Create cloud-init.yaml file from template with SSH public key
function generate_cloud_init_config_from_template() {
    local CLOUD_INIT_TEMPLATE_FILE="config/templates/cloud-init.yaml"
    local CLOUD_INIT_CONFIG_FILE="config/generated/pre-vm-creation/cloud-init.yaml"
    if [ -f "$CLOUD_INIT_CONFIG_FILE" ]; then
        echo "$CLOUD_INIT_CONFIG_FILE exists"
        echo " ${ORANGE}Reusing Existing $CLOUD_INIT_CONFIG_FILE${NC} Config Files"
        return 0
    fi
    echo "${BOLD}Generating $CLOUD_INIT_CONFIG_FILE Config Files...${NC}"
    cp "$CLOUD_INIT_TEMPLATE_FILE" "$CLOUD_INIT_CONFIG_FILE"
    file_replace_text "ssh-rsa.*$" "$(cat "$SSH_KEY_PATH"/"${SSH_KEY}".pub)" "$CLOUD_INIT_CONFIG_FILE"
    echo "${GREEN} $CLOUD_INIT_CONFIG_FILE Generation Done! ${NC}"
}

## Create ssh-config file from template with IP OCTET Pattern
function generate_ssh_config_from_template() {
    local SSH_TEMPLATE_FILE="config/templates/ssh-config"
    local SSH_CONFIG_FILE="config/generated/pre-vm-creation/ssh-config"
    OCTET=$1
    if [ -f "$SSH_CONFIG_FILE" ]; then
        echo "$SSH_CONFIG_FILE exists"
        echo "${ORANGE}Reusing Existing SSH Config Files${NC}"
        return 0
    fi
    echo "${BOLD}Generating $SSH_CONFIG_FILE Config File...${NC}"
    cp "$SSH_TEMPLATE_FILE" "$SSH_CONFIG_FILE"
    # IP=$(multipass info "$VM_NAME" | grep IPv4 | awk '{print $2}')
    # OCTET=$(echo $IP | awk -F '.' '{ print $1}')
    file_replace_text "_GATEWAY_IP_.*$" "$OCTET" "$SSH_CONFIG_FILE"
    # file_replace_text "_USER_.*$" "$SSH_USER" "$SSH_CONFIG_FILE"
    echo "${GREEN}$SSH_CONFIG_FILE Generation Done! ${NC}"
}

# Check Configuration State
function is_configuration_done(){
  config=$1
  local state_file="config/generated/post-vm-creation/vm.state"
  CONF_STATE=$(cat $state_file | grep -c $config)
  # If Not Already Configured
  if [ $CONF_STATE -eq "0" ];then
    return 1
  else
    return 0
  fi
}

# Generate & Check for Configuration Files
function generate_pre_vm_config_files(){
  local state_file="config/generated/post-vm-creation/vm.state"
  if [ -f $state_file ];then
    is_configuration_done ".conf.preparation=done" &&
      raise_error "Preparation Already Done. Exiting..."
  fi 
  echo -e "\n${BOLD}${UNDERLINE}🧪 Prerequisites Checks...${NC}\n"
  exit_on_pre_condition_checks

  # VMs
  local vms_list_template_file="config/templates/vms.list"
  local vms_list_config_file="config/generated/pre-vm-creation/vms.list"
  generate_confirm_config_file "$vms_list_template_file" "$vms_list_config_file"

  # Apps
  local apps_list_template_file="config/templates/apps.list"
  local apps_list_config_file="config/generated/pre-vm-creation/apps.list"
  generate_confirm_config_file "$apps_list_template_file" "$apps_list_config_file"

  # Add .vault_password file for MMonit
  local vault_password_file="config/generated/post-vm-creation/.vault_password"
  add_confirm_config_file "$vault_password_file"

  # scripts/lib/ssh.sh
  generate_ssh_key

  # cloud-init.yaml
  generate_cloud_init_config_from_template

  # User Mgmt
  local duo_template_file="config/templates/duo.env.sample"
  local duo_config_file="config/generated/post-vm-creation/duo.env"
  generate_confirm_config_file "$duo_template_file" "$duo_config_file"

  local SSH_PUBLIC_KEY="config/generated/pre-vm-creation/id_rsa.pub"
  file_replace_text "_CEC_USER_.*$" "${USER}" "${duo_config_file}"
  source "$duo_config_file"

  local state_file="config/generated/post-vm-creation/vm.state"
  echo  "$(date), .conf.preparation=done">> "$state_file"
  echo -e "\n - 🍻 ${BOLD}${GREEN}All DONE!${NC}\n"
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
      config/generated/post-vm-creation/duo.env \
      config/generated/post-vm-creation/.vault_password
}
