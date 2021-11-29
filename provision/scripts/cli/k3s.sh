#!/usr/bin/env bash

set -eo pipefail

function k3s_manager() {
  action="$2"
  case $action in
  up)
    run "ansible-playbook playbooks/k3s/prereq.yml"
    run "ansible-playbook playbooks/k3s/setup.yml"
    run "ansible-playbook playbooks/k3s/post-setup.yml"
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