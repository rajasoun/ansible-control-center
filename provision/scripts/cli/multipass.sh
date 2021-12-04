#!/usr/bin/env bash

set -eo pipefail

# shellcheck source=scripts/lifecycle/multipass.sh"
source "$SCRIPT_DIR/lifecycle/multipass.sh"

function multipass_manager() {
  action="$2"
  case $action in
  prepare)
    run_prepare
        check_for_dot_env_files
        echo -e "${GREEN}\nNext Run From ${UNDERLINE}Host${NC} ->  ./assist.sh local up  \n${NC}"
    ;;
  up)
    if [ ! -f config/generated/pre-vm-creation/vms.list ]; then
      run_prepare
      confirm
    fi
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
    echo -e "${GREEN}\nNext Run From ${UNDERLINE}Host${NC} ->  ./assist.sh configure prepare  \n${NC}"
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
    display_apps_status "config/generated/pre-vm-creation/apps.list"
    ;;
  *)
    cat <<-EOF
sandbox commands:
----------------
  prepare            -> Prerequsites Check & Config Preparation
  up                 -> spin up the multipass sandbox environment
  down               -> tear down the multipass sandbox environment
  status             -> displays status
EOF
    ;;
  esac
}
