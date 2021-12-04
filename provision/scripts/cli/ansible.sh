#!/usr/bin/env bash

set -eo pipefail

function ansible_manager() {
  action="$2"
  case $action in
  prepare)
      is_vm && raise_error "prepare can't run from VM"
      check_vms_provision_state
      echo "Prepare Control Center from Local Host..."
      prepare_control_center
      ;;
  control-center)
    #! is_vm && raise_error "configure can't run from host"
    echo "Configure Control Center..."
    configure_control_center
    ;;
  users)
    #is_vm && raise_error "user configuration can't run on vm"
    echo "Configure Users..."
    configure_users
    echo -e "${GREEN}\nNext  SSH to Control Center -> ./assist.sh login control-center $USER \n${NC}"
    ;;
  k3s)
    ! is_vm && raise_error "k3s can't run on host"
    run "ansible-playbook playbooks/k3s/prereq.yml"
    run "ansible-playbook playbooks/k3s/setup.yml"
    run "ansible-playbook playbooks/k3s/post-setup.yml"
    ;;
  monitor)
    ! is_vm && raise_error "k3s can't run on host"
    configure_mmonit
    configure_monit
    ;;
  status)
    local state_file="config/generated/post-vm-creation/vm.state"
    echo -e "$(cat $state_file)"
    ;;
  *)
    cat <<-EOF
sandbox commands:
----------------
  prepare            -> Transfer Configuration Files to Control Center
  control-center     -> Configure Control Center
  users              -> Configure User with MFA
  monitor            -> Configure Monitoring
  k3s                -> Configure k3s
  status             -> Displays status of the Configuration
EOF
    ;;
  esac
}
