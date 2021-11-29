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
  configure)
    ! is_vm && raise_error "configure can't run from host"
    echo "Configure Control Center..."
    echo "If this is your first time starting sandbox this might take a minute..."
    configure_control_center
    configure_mmonit
    configure_monit
    ;;
  status)
    echo "Querying VMs status (ansible ping)..."
    #ansible_runner "ansible-playbook playbooks/ping.yml"
    run "ansible -m ping vms"
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
  configure          -> Configure Control Center
  status             -> Displays status - ansible ping
  run                -> Run Ansible Command
EOF
    ;;
  esac
}


 