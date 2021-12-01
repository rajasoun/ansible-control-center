# asnible-control-center

Ansible Control Center in provisioning infrastructure vms
locally, or in Openstack

## Pre Requisites

-   [multipass](https://multipass.run/) for local setup
-   [docker](https://www.docker.com/) for cloud setup

## Getting Started

0. Add .vault_password fro MMonit license and SSL Certificates

-   Add `ssl_certificate.crt` to `config/ssl-certs` directory
-   Add `ssl_certificate_key.key` to `config/ssl-certs` directory
-   Add `.vault_password` to `config/generated/post-vm-creation` directory - MMOnit License Version
-   Add `duo.env` to `config/generated/post-vm-creation` directory for MFA support

1. Prepare Configuration Files  

```
./assist.sh local prepare
```

2. Edit `config/generated/pre-vm-creation/vms.list` to match the needs


3. Proivision VMs

```
./assist.sh local up
```

4. Configure VMs

```
./assist.sh ansible prepare
./assist.sh local   enter
./assist.sh ansible configure
```

4. Install Dcoker and Docker-Compose in observability, dashboard and reverse-proxy

```
ansible-playbook playbooks/observability.yml
ansible-playbook playbooks/reverse-proxy.yml
```

> As and when new nodes are being added, do the following

1. Add the node to the `inventory` file
2. Execute following Playbboks for User Mgmt, Monitoring and Host Mappings in control-center

```
provision/ansible/run.sh "ansible-playbook playbooks/configure-vm.yml"
```

## k3s Setup

k3s Ansible Setup

```
kubectl -n kubernetes-dashboard describe secret admin-user-token | grep '^token'
kubectl proxy

Visit -> http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

```

## wrapper runner 

```
./assist.sh wrapper run "bash"
```
