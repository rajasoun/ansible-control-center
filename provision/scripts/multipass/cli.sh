#!/usr/bin/env bash

set -eo pipefail


function multipass_manager() {
  action="$2"
  case $action in
  prepare)
    echo -e "\n${BOLD}${UNDERLINE}🧪 Prerequisites Checks...${NC}\n"
    exit_on_pre_condition_checks
    generate_pre_vm_config_files
    echo -e "\n ${BOLD}${BLUE}Edit ${UNDERLINE}config/generated/pre-vm-creation/vms.list${NC} (optional)\n${NC}"
    ;;
  up)
    start=$(date +%s)
    echo "Spinning up multipass sandbox environment..."
    echo "If this is your first time starting sandbox this might take a minute..."
    # add_host_entries
    # generate_pre_vm_config_files
    create_vm_provisioning_commands
    provision_vms
    generate_post_vm_config_files
    end=$(date +%s)
    runtime=$((end-start))
    echo -e "${GREEN}${BOLD}VM Provision Done! | Duration:  $(display_time $runtime)${NC}"
    ;;
  down)
    echo "Stopping multipass sandbox containers..."
    # remove_host_entries
    teardown
    clean_generated_config_files
    ;;
  status)
    echo "Querying multipass sandbox status..."
    multipass list 
    display_apps_status 
    ;;
  enter)
    shell_to_control_center
    ;;
  *)
    cat <<-EOF
sandbox commands:
----------------
  precheck           -> Prerequsites Check
  up                 -> spin up the multipass sandbox environment
  down               -> tear down the multipass sandbox environment
  status             -> displays status 
  enter              -> enter the control-center
EOF
    ;;
  esac
}


 