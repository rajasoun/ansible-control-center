#!/usr/bin/env bash

set -eo pipefail

function ansible_manager() {
  action="$2"
  case $action in
  vms)
      is_vm && raise_error "prepare can't run from VM"
      check_vms_provision_state
      echo "Prepare All VMs..."
      prepare_vms
      ;;
  users)
    is_vm && raise_error "user configuration can't run on vm"
    echo "Configure Users..."
    configure_users
    echo -e "${GREEN}\nNext  SSH to Control Center -> ./assist.sh login control-center $USER \n${NC}"
    ;;
  host-mappings)
    #! is_vm && raise_error "configure can't run from host"
    echo "Configure Host Mappings in /etc/hosts ..."
    configure_etc_host_mappings
    ;;
  k3s)
    ! is_vm && raise_error "k3s can't run on host"
    run "ansible-playbook playbooks/k3s/prereq.yml"
    run "ansible-playbook playbooks/k3s/setup.yml"
    run "ansible-playbook playbooks/k3s/post-setup.yml"
    ;;
  monitor)
    ! is_vm && raise_error "k3s can't run on host"
    run "ansible-galaxy install -r playbooks/dependencies/monitoring/requirements.yml"
    configure_mmonit
    configure_monit
    ;;
  status)
    local state_file="config/generated/post-vm-creation/vm.state"
    #echo -e "$(cat $state_file)"
    pretty_table_print "$state_file"
    ;;
  *)
    cat <<-EOF
sandbox commands:
----------------
  vms                -> Package Upgrade and Install - Run from Host
  users              -> Configure User with MFA - Run from Host
  monitor            -> Configure Monitoring - Run from control-center
  k3s                -> Configure k3s - Run from control-center
  host-mappings      -> Configure Control Center
  status             -> Displays status of the Configuration
EOF
    ;;
  esac
}
