#!/usr/bin/env bash

CONFIG_TEMPLATE_PATH="config/templates"
CONFIG_PATH="config/generated"

SSH_KEY_PATH="${CONFIG_PATH}/pre-vm-creation"
SSH_KEY="id_rsa"
SSH_USER="ansible"

## Generate SSH Keys
function generate_ssh_key() {
    if [ -f "$SSH_KEY_PATH/${SSH_KEY}" ]; then
        echo "Reusing Existing SSH Keys"
        return 0
    fi
    echo "Generating SSH Keys..."
    echo -e 'y\n' | ssh-keygen -q -t rsa -C \
                            "$(id -un)@$DOMAIN" -N "" \
                            -f "$SSH_KEY_PATH/${SSH_KEY}" 2>&1 > /dev/null 2>&1
    # Fix Permission For Private Key
    chmod 400 "$SSH_KEY_PATH"/"${SSH_KEY}"
    echo "${GREEN}${SSH_KEY} & ${SSH_KEY}.pub keys Generation Done! ${NC}"
}

## Check SSH Private Key File Exists
function check_ssh_private_key_exists() {
    if [ ! -f "$(cat "$SSH_KEY_PATH"/"${SSH_KEY}")" ];then
       echo "${BOLD}${RED} SSH Private Key File $SSH_KEY_PATH/${SSH_KEY}.pub Not Exist${NC}"
       return 1
    fi
}

## Generate SSH Public Key from Private Key File
function generate_ssh_public_key_from_private_key(){
    if [ check_ssh_private_key_exists ]; then
        if [ -f "$(cat $SSH_KEY_PATH/${SSH_KEY})" ];then
            PUBLIC_KEY_FROM_PRIVATE_KEY="$(ssh-keygen -y -f $SSH_KEY_PATH/${SSH_KEY})"
            echo $PUBLIC_KEY_FROM_PRIVATE_KEY > "$SSH_KEY_PATH/${SSH_KEY}.pub"
            return 0
        else
            echo "${BOLD}${RED} SSH Private Key $SSH_KEY_PATH File Not Exist. Exiting... ${NC}"
            return 1
        fi
    fi
}

## Check SSH Public Key File matches with Private Key File
function check_ssh_public_private_key_pair(){
    if [ check_ssh_private_key_exists ]; then
        # If Public Key File Not Available. Generate From Private Key File
        [ ! -f $SSH_KEY_PATH/${SSH_KEY}.pub ] || generate_ssh_public_key_from_private_key
        DIFF=$(diff <(cut -d' ' -f 2 $SSH_KEY_PATH/${SSH_KEY}.pub) <(ssh-keygen -y -f $SSH_KEY_PATH/${SSH_KEY} | cut -d' ' -f 2) | wc -l)
        if [ $DIFF -eq "0" ]; then
            echo "${BOLD}${GREEN} SSH Public Private Key Pair Matches ${NC}"
            return 0
        else
            echo "${BOLD}${RED} SSH Public Private Key Pair Does Not Matche ${NC}"
            return 1
        fi
    fi
}

## Create cloud-init.yaml file from template with SSH public key
function create_cloud_init_config_from_template() {
    local CLOUD_INIT_TEMPLATE_FILE="${CONFIG_TEMPLATE_PATH}/cloud-init.yaml"
    local CLOUD_INIT_CONFIG_FILE="${CONFIG_PATH}/cloud-init.yaml"

    if [ -f "$CLOUD_INIT_CONFIG_FILE" ]; then
        echo "$CLOUD_INIT_CONFIG_FILE exists"
        echo " ${ORANGE}Reusing Existing $CLOUD_INIT_CONFIG_FILE${NC} Config Files"
        return 0
    fi
    echo "${BOLD}Generating $CLOUD_INIT_CONFIG_FILE Config Files...${NC}"
    cp "$CLOUD_INIT_TEMPLATE_FILE" "$CLOUD_INIT_CONFIG_FILE"
    file_replace_text "ssh-rsa.*$" "$(cat "$SSH_KEY_PATH"/"${SSH_KEY}".pub)" "$CLOUD_INIT_CONFIG_FILE"
    echo "${GREEN} $CLOUD_INIT_CONFIG_FILE Generation Done! ${NC}"
}

## Create ssh-config file from template with IP OCTET Pattern
function create_ssh_config_from_template() {
    local SSH_TEMPLATE_FILE="${CONFIG_TEMPLATE_PATH}/ssh-config"
    local SSH_CONFIG_FILE="${CONFIG_PATH}/ssh-config"
    OCTET=$1
    if [ -f "$SSH_CONFIG_FILE" ]; then
        echo "$SSH_CONFIG_FILE exists"
        echo "${ORANGE}Reusing Existing SSH Config Files${NC}"
        return 0
    fi
    echo "${BOLD}Generating $SSH_CONFIG_FILE Config File...${NC}"
    cp "$SSH_TEMPLATE_FILE" "$SSH_CONFIG_FILE"
    # IP=$(multipass info "$VM_NAME" | grep IPv4 | awk '{print $2}')
    # OCTET=$(echo $IP | awk -F '.' '{ print $1}')
    file_replace_text "_GATEWAY_IP_.*$" "$OCTET" "$SSH_CONFIG_FILE"
    # file_replace_text "_USER_.*$" "$SSH_USER" "$SSH_CONFIG_FILE"
    echo "${GREEN}$SSH_CONFIG_FILE Generation Done! ${NC}"
}

function ping_check(){
    run "ansible -m ping $vm"
    case "$?" in
        0)
            echo "${GREEN}Ping Check for $vm SUCCESSFULL ${NC}" ;;
        1)
            echo "${RED}Ping Check for $vm FAILED. Exiting... ${NC}"
            exit 1
            ;;
    esac
}

### SSH to VM using ansible inventory
function ansible-ssh() {
    user="$3"
    if [ -z $user ]; then
        read -rp "ssh user: " user
    fi

    ssh_args="-o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes"
    ssh_private_key="-i config/generated/pre-vm-creation/id_rsa"

    vm=$(ansible-inventory --list | jq -cr --arg user $user 'to_entries | .[] | select(.value.hosts) | (.value.hosts[])' | fzf)
    ip="$(ansible-inventory --host $vm | jq -cr '"\(.ansible_ssh_host)"')"
    sshLoginHost="$user@$ip"

    if [ ["$sshLoginHost" = ""] ]; then
        # ex) Ctrl-C.
        echo "${RED}$vm Not Availablee in the Inventory${NC}"
        return 1
    fi
    ping_check $vm
    echo "${GREEN} ssh $user@$ip ${NC}"
    confirm
    bash -c "ssh ${ssh_args} ${sshLoginHost} ${ssh_private_key}"
}

### SSH to VM using ansible inventory
function ssh-login() {
    vm=$2
    user=$3
    if [ ! -f "config/generated/post-vm-creation/inventory" ]; then
        echo "${RED}${BOLD}Inventory File Not Availabe. Exiting...${NC}"
        exit 1
    fi
    if [[ " -z $vm " ||  "-z $user"  ]];then
        echo -e "${RED}${BOLD}Parameters Not Prement: VM -> $vm | user -> $user ${NC}"
        echo -e "${GREEN} Switching to Interactive Mode ${NC}"
        ansible-ssh "$@"
    fi

    ssh_args="-o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes"
    ssh_private_key="-i config/generated/pre-vm-creation/id_rsa"

    ip="$(ansible-inventory --host $vm | jq -cr '"\(.ansible_ssh_host)"')"
    sshLoginHost="$user@$ip"

    if [ ["$sshLoginHost" = ""] ]; then
        # ex) Ctrl-C.
        echo "${RED}$vm Not Availablee in the Inventory${NC}"
        return 1
    fi
    ping_check $vm
    echo "${GREEN} ssh $user@$ip ${NC}"
    confirm
    bash -c "ssh ${ssh_args} ${sshLoginHost} ${ssh_private_key}"
}
