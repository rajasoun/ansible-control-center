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
    wrapper_runner "$@"
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

function wrapper_runner() {
    # Only allocate tty if one is detected. See - https://stackoverflow.com/questions/911168
    if [[ -t 0 ]]; then IT+=(-i); fi
    if [[ -t 1 ]]; then IT+=(-t); fi

    echo "Running in Wrapper Container"
    _docker run --rm "${IT[@]}"  \
        --hostname control-center \
        --name control-center \
        --workdir /ansible \
        --user ansible \
        -v "${PWD}:/ansible" \
        -v "${PWD}/config/generated/pre-vm-creation/id_rsa:/home/ubuntu/.ssh/id_rsa" \
        -v "${PWD}/config/generated/post-vm-creation/ssh-config:/home/ubuntu/.ssh/ssh-config" \
        -v "${PWD}/.ansible:/home/ansible/.ansible" \
        rajasoun/wrapper-runner:0.1.0 bash -c "$@"

    case "$?" in
        0)
            echo "SUCCESSFULL " ;;
        1)
            echo "FAILED " ;;
    esac
}

# check vm provision done
function check_vms_provision_state(){
    local state_file="config/generated/post-vm-creation/vm.state"
    ERR_MSG="\n${RED}VM Conf State is Empty.Exiting... ${NC}"
    CONF_STATE=$(cat $state_file | grep -c .vms.provision=done) || echo -e "$ERR_MSG"
    # If Not Already Configured
    if [ $CONF_STATE -eq "0" ];then
        echo -e "${BOLD}${BLUE}Run -> ./assist.sh local up ${NC}\n"
        exit 1
    else
        echo -e "${GREEN} VM Provision Check | Successfull | Ref: $state_file  ${NC}"
        return 0
    fi
}
# Configure Control Center based on state file
function configure_etc_host_mappings(){
    echo "${GREEN}Configure ETC Host Mapping ${NC}"
    CONF_STATE=$(cat $STATE_FILE | grep -c .etc.hosts.mappings.conf=done) || echo "${RED}control-center Conf State is Empty${NC}"
    # If Not Already Configured
    if [ $CONF_STATE -eq "0" ];then
        echo "${GREEN} Configuring Host Mappings in /etc/hosts ${NC}"
        run "ansible-playbook playbooks/control-center/etc.yml"
        echo "${BOLD}${GREEN}Host Mappings Configuration Done!${NC}"
        echo "$(date), .etc.hosts.mappings.conf=done" >> "$STATE_FILE"
        echo -e "${GREEN}\nNext  Configure Users -> ./assist.sh configure users \n${NC}"
    else
        echo "${BLUE} Skipping control-center Configuration ${NC}"
        echo "${ORANGE} Edit $STATE_FILE to remove .etc.hosts.mappings.conf=done ${NC}"
    fi
}

# Configure MMonit
function configure_mmonit(){
    local PLAYBOOK_HOME=$HOME/ansible-control-center/playbooks
    local MMONIT_LICENSE="$HOME/.ansible/roles/rajasoun.ansible_role_mmonit/files/license.yml"

    echo "${GREEN}mmonit - configuration${NC}"
    CONF_STATE=$(cat $STATE_FILE | grep -c .mmonit.conf=done) || echo "${RED}mmonit Conf State is Empty${NC}"
    # If Not Already Configured
    if [ $CONF_STATE -eq "0" ];then
        echo "${GREEN} Configuring MMonit ${NC}"
        run "ansible-vault decrypt $MMONIT_LICENSE --vault-password-file $HOME/ansible-managed/.vault_password"
        echo "${GREEN}MMonit License Decrypt Done${NC}"
        run "ansible-playbook $PLAYBOOK_HOME/mmonit.yml"
        echo "${GREEN}MMonit Installation & Configuration Done!${NC}"
        run "ansible-vault encrypt $MMONIT_LICENSE --vault-password-file $HOME/ansible-managed/.vault_password"
        echo "MMonit License Encryption Done"
        echo "$(date), .mmonit.conf=done" >> "$STATE_FILE"
    else
        echo "${BLUE} Skipping mmonit Configuration ${NC}"
        echo "${ORANGE} Edit $STATE_FILE to remove .mmonit.conf=done ${NC}"
    fi
}

# Configure Monit
function configure_monit(){
    local PLAYBOOK_HOME=$HOME/ansible-control-center/playbooks

    echo "${GREEN}monit - configuration${NC}"
    CONF_STATE=$(cat $STATE_FILE | grep -c .monit-agent.conf=done) || echo "${RED}monit Conf State is Empty${NC}"
    # If Not Already Configured
    if [ $CONF_STATE -eq "0" ];then
        echo "${GREEN} Configuring Monit ${NC}"
        # Install & Configure Monit
        run "ansible-playbook $PLAYBOOK_HOME/monit.yml"
        echo "${GREEN}Monit Installation & Configuration Done!${NC}"
        echo "$(date), .monit-agent.conf=done" >> "$STATE_FILE"
    else
        echo "${BLUE} Skipping monit Configuration ${NC}"
        echo "${ORANGE} Edit $STATE_FILE to remove .monit-agent.conf=done ${NC}"
    fi
}

# Configure Monit
function configure_users(){
    local PLAYBOOK_HOME=$HOME/playbooks
    echo "${GREEN}users - configuration${NC}"
    ERR_MSG="Control Center Conf State is Empty.Exiting...\n Run -> ./assist.sh configure control-center"
    CONF_STATE=$(cat $STATE_FILE | grep -c .control-center.configure.conf=done) || raise_error "$ERR_MSG"
    CONF_STATE=$(cat $STATE_FILE | grep -c .users.conf=done) || echo "${RED}users Conf State is Empty${NC}"
    # If Not Already Configured
    if [ $CONF_STATE -eq "0" ];then
        echo "${GREEN} Configuring Users ${NC}"
        # Configure Users
        run "ansible-galaxy install -r playbooks/dependencies/user-mgmt/requirements.yml"
        run "source config/generated/post-vm-creation/duo.env && ansible-playbook playbooks/user-mgmt/duo.yml"
        echo "${GREEN}Users Configuration Done!${NC}"
        echo "$(date), .users.conf=done" >> "$STATE_FILE"
    else
        echo "${BLUE} Skipping users Configuration ${NC}"
        echo "${ORANGE} Edit $STATE_FILE to remove .users.conf=done ${NC}"
    fi
}

# Configure Control Center based on state file
function prepare_vms(){
    local SSH_PUBLIC_KEY="config/generated/pre-vm-creation/id_rsa.pub"

    echo "${GREEN}control-center ${NC}"
    CONF_STATE=$(cat $STATE_FILE | grep -c .vms.conf=done) || echo "${RED}control-center Conf State is Empty${NC}"
    # If Not Already Configured
    if [ $CONF_STATE -eq "0" ];then
        echo "${GREEN} Preparing control-center ${NC}"
        run "ansible-playbook playbooks/apt-packages.yml"
        run "ansible-playbook playbooks/control-center/prepare.yml"
        echo "${BOLD}${GREEN}Control Center Preparation Done!${NC}"
        echo "$(date), .vms.conf=done" >> "$STATE_FILE"
        echo -e "${GREEN}\nNext  Configure Control Center -> ./assist.sh configure control-center \n${NC}"
    else
        echo "${BLUE} Skipping control-center Preparation ${NC}"
        echo "${ORANGE} Edit $STATE_FILE to remove .vms.conf=done ${NC}"
    fi
}
