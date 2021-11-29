#!/usr/bin/env bash

set -eo pipefail
IFS=$'\n\t'

VM_NAME=${VM_NAME:-"control-center"}
ANSIBLE_HOME=${ANSIBLE_HOME:-"$HOME/ansible-control-center"}

STATE_FILE="config/generated/post-vm-creation/vm.state"

function run(){
  # If Ansible Not Available - Run Via Docker
  if  [ `hostname` == "control-center"  ]; then
    bash -c "$@"
  else
    ansible_runner "$@"
  fi
}

# Workaround for Path Limitations in Windows
function _docker() {
  export MSYS_NO_PATHCONV=1
  export MSYS2_ARG_CONV_EXCL='*'

  case "$OSTYPE" in
      *msys*|*cygwin*) os="$(uname -o)" ;;
      *) os="$(uname)";;
  esac

  if [[ "$os" == "Msys" ]] || [[ "$os" == "Cygwin" ]]; then
      # shellcheck disable=SC2230
      realdocker="$(which -a docker | grep -v "$(readlink -f "$0")" | head -1)"
      printf "%s\0" "$@" > /tmp/args.txt
      # --tty or -t requires winpty
      if grep -ZE '^--tty|^-[^-].*t|^-t.*' /tmp/args.txt; then
          #exec winpty /bin/bash -c "xargs -0a /tmp/args.txt '$realdocker'"
          winpty /bin/bash -c "xargs -0a /tmp/args.txt '$realdocker'"
          return 0
      fi
  fi
  docker "$@"
  return 0
}

function ansible_runner() {
    if [ ! -f "config/generated/post-vm-creation/inventory" ]; then
        echo "Inventory File Not Availabe. Exiting..."
        exit 1
    fi
    # Only allocate tty if one is detected. See - https://stackoverflow.com/questions/911168
    if [[ -t 0 ]]; then IT+=(-i); fi
    if [[ -t 1 ]]; then IT+=(-t); fi

    echo "Running $1 in Ansible Container"
    _docker run --rm "${IT[@]}"  \
        --hostname control-center \
        --name control-center \
        --workdir /ansible \
        --user ansible \
        -v "${PWD}:/ansible" \
        -v "${PWD}/config/generated/pre-vm-creation/id_rsa:/home/ubuntu/.ssh/id_rsa" \
        -v "${PWD}/config/generated/post-vm-creation/ssh-config:/home/ubuntu/.ssh/ssh-config" \
        -v "${PWD}/.ansible:/home/ansible/.ansible" \
        cytopia/ansible:latest-tools bash -c "$@"

    case "$?" in
        0)
            echo "SUCCESSFULL " ;;
        1)
            echo "FAILED " ;;
    esac
}


# Configure Control Center based on state file
function configure_control_center(){
    echo "${GREEN}control-center ${NC}"
    CONF_STATE=$(cat $STATE_FILE | grep -c .control-center.configure.conf=done) || echo "${RED}control-center Conf State is Empty${NC}"
    # If Not Already Configured
    if [ $CONF_STATE -eq "0" ];then
        echo "${GREEN} Configuring control-center ${NC}"
        run "ansible-playbook playbooks/apt-packages.yml"
        run "ansible-galaxy install -r playbooks/dependencies/monitoring/requirements.yml"
        echo "${BOLD}${GREEN}Control Center Configuration Done!${NC}"
        echo ".control-center.configure.conf=done" >> "$STATE_FILE"
    else
        echo "${BLUE} Skipping control-center Configuration ${NC}"
    fi
}

# Configure Control Center based on state file
function prepare_control_center(){
    echo "${GREEN}control-center ${NC}"
    CONF_STATE=$(cat $STATE_FILE | grep -c .control-center.prepare.conf=done) || echo "${RED}control-center Conf State is Empty${NC}"
    # If Not Already Configured
    if [ $CONF_STATE -eq "0" ];then
        [ !check_if_vm ] || raise_error "prepare can't run on VM"
        echo "${GREEN} Preparing control-center ${NC}"
        run "ansible-playbook playbooks/control-center/prepare.yml"
        run "ansible-galaxy install -r playbooks/dependencies/user-mgmt/requirements.yml"
        echo "${BOLD}${GREEN}Control Center Preparation Done!${NC}"
        echo ".control-center.prepare.conf=done" >> "$STATE_FILE"
    else
        echo "${BLUE} Skipping control-center Preparation ${NC}"
    fi
}



