#!/usr/bin/env bash

set -eo pipefail

function wrapper_manager() {
  action="$2"
  case $action in
  run)
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