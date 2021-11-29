#!/usr/bin/env bash

set -eo pipefail

function k3s_manager() {
  action="$2"
  case $action in
  up)
    run "playbooks/k3s/prereq.yml"
    run "playbooks/k3s/setup.yml"
    run "playbooks/k3s/post-setup.yml"
    ;;
  *)
    cat <<-EOF
sandbox commands:
----------------
  up  -> Setup k3s cluster
EOF
    ;;
  esac
}