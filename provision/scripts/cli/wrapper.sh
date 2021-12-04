#!/usr/bin/env bash

set -eo pipefail

function wrapper_manager() {
  action="$2"
  case $action in
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
  run                -> Wrapper Runner for ansible, aws, openstack
EOF
    ;;
  esac
}
