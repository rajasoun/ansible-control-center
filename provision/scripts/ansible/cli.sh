#!/usr/bin/env bash

set -eo pipefail

function run(){
  echo "${GRAY}$(cat "$CONFIG_PATH/vms.list")${NC}"
  # If Ansible Not Available - Run Via Docker
  if  [ hostname == "control-center"  ]; then
    bash -c "$@"
  else
    ansible_runner "$@"
  fi
}

function ansible_manager() {
  action="$2"
  case $action in
  up)
    echo "Configuring sandbox environment..."
    echo "If this is your first time starting sandbox this might take a minute..."
    configure_control_center
    ;;
  down)
    echo "Stopping multipass sandbox containers..."
    ;;
  status)
    echo "Querying VMs status (ansible ping)..."
    #ansible_runner "ansible-playbook playbooks/ping.yml"
    run "ansible -m ping vms"
    ;;
  run)
    run "$@"
    ;;
  *)
    cat <<-EOF
sandbox commands:
----------------
  up                 -> configure all vms in sandbox environment
  down               -> stop all vms in sandbox environment
  status             -> displays status - ansible ping
  run                -> Run Ansible Command
EOF
    ;;
  esac
}


 