#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )"

# shellcheck source=scripts/lib/os.sh
source "$SCRIPT_DIR/lib/os.sh"
# shellcheck source=scripts/lib/ssh.sh
source "$SCRIPT_DIR/lib/ssh.sh"
# shellcheck source=scripts/lib/etc_hosts.sh
source "$SCRIPT_DIR/lib/etc_hosts.sh"
# shellcheck source=scripts/multipass/cli.sh
source "$SCRIPT_DIR/multipass/cli.sh"
# shellcheck source=scripts/multipass/lifecycle.sh
source "$SCRIPT_DIR/multipass/lifecycle.sh"
# shellcheck source=scripts/ansible/cli.sh
source "$SCRIPT_DIR/ansible/cli.sh"
# shellcheck source=scripts/ansible/run.sh
source "$SCRIPT_DIR/ansible/lifecycle.sh"