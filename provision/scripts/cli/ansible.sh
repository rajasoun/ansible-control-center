#!/usr/bin/env bash

set -eo pipefail

function ansible_manager() {
  action="$2"
  case $action in
  prepare)
      is_vm && raise_error "prepare can't run from VM"
      echo "Prepare Control Center from Local Host..."
      prepare_control_center
      ;;
  control-center)
    ! is_vm && raise_error "configure can't run from host"
    echo "Configure Control Center..."
    configure_control_center
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
  login)
    ansible-ssh "$@"
    ;;
  status)
    echo "Querying VMs status (ansible ping)..."
    run "ansible-playbook playbooks/ping.yml"
    ;;
  run)    
    if [ ! -f "config/generated/post-vm-creation/inventory" ]; then
        echo "Inventory File Not Availabe. Exiting..."
        exit 1
    fi
    run "$3"
    ;;
  *)
    cat <<-EOF
sandbox commands:
----------------
  prepare            -> Transfer Configuration Files to Control Center
  control-center     -> Configure Control Center
  monitor            -> Configure Monitoring 
  k3s                -> Configure k3s
  status             -> Displays status - ansible ping
  login              -> SSH to the VM
  run                -> Run Ansible Command
EOF
    ;;
  esac
}


 