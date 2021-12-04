#!/usr/bin/env bash

set -eo pipefail

# shellcheck source=scripts/lifecycle/multipass.sh"
source "$SCRIPT_DIR/lifecycle/multipass.sh"

function multipass_manager() {
  action="$2"
  case $action in
  prepare)
    generate_pre_vm_config_files
    echo -e "${GREEN}\nNext Run From ${UNDERLINE}Host${NC} ->  ./assist.sh local up  \n${NC}"
    ;;
  up)
    is_vm && raise_error "up can't run from VM."
    if [ ! -f config/generated/pre-vm-creation/vms.list ]; then
      generate_pre_vm_config_files
    fi
    start=$(date +%s)
    echo "Spinning up multipass sandbox environment..."
    echo "If this is your first time starting sandbox this might take a minute..."
    generate_vm_provisioning_scipts
    provision_vms_from_script
    generate_post_vm_config_files
    #mount_dot_ansible_to_control_center
    end=$(date +%s)
    runtime=$((end-start))
    echo -e "${GREEN}${BOLD}VM Provision Done! | Duration:  $(display_time $runtime)${NC}"
    echo -e "${GREEN}\nNext Run From ${UNDERLINE}Host${NC} ->  ./assist.sh configure vms \n${NC}"
    ;;
  down)
    echo "Stopping multipass sandbox containers..."
    # remove_host_entries
    teardown_multipass_setup
    clean_generated_config_files
    ;;
  status)
    echo "Querying multipass sandbox status..."
    multipass list
    echo ""
    echo "Querying VMs status (ansible ping via Playbook)..."
    run "ansible-playbook playbooks/ping.yml"
    echo ""
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
