#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )"

### LIBS ####
# shellcheck source=scripts/lib/os.sh
source "$SCRIPT_DIR/lib/os.sh"
# shellcheck source=scripts/lib/ssh.sh
source "$SCRIPT_DIR/lib/ssh.sh"
# shellcheck source=scripts/lib/etc_hosts.sh
source "$SCRIPT_DIR/lib/etc_hosts.sh"
# shellcheck source=scripts/lib/wrapper.sh
source "$SCRIPT_DIR/lib/wrapper.sh"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

### CLI - UI ####
# shellcheck source=scripts/cli/multipass.sh"
source "$SCRIPT_DIR/cli/multipass.sh"
# shellcheck source=scripts/cli/wrapper.sh"
source "$SCRIPT_DIR/cli/wrapper.sh"
# shellcheck source=scripts/cli/ansible.sh"
source "$SCRIPT_DIR/cli/ansible.sh"



