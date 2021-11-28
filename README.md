# asnible-control-center

Ansible Control Center in provisioning infrastructure vms
locally, or in Openstack

## Pre Requisites

-   [multipass](https://multipass.run/) for local setup
-   [docker](https://www.docker.com/) for cloud setup

## Getting Started

0. Add .vault_password fro MMonit license and SSL Certificates

-   Add `.vault_password` to `keys` directory with the vault password
-   Add `ssl_certificate.crt` to `keys` directory
-   Add `ssl_certificate_key.key` to `keys` directory

1. Create Infrastructure VMs locally or in cloud
    - control-center
    - mmonit
    - observability
    - reverse-proxy

```
./assist.bash {multipass | openstack}
```

Multipass Specific (Local)

```
./assist.bash multipass
```

Open Stack (On Prem Cloud)

```
provision/openstack/shell/run.sh
source config/{stage|production}/<openrc.sh>
cd /workspace
```

2. Install & Configure MMonit/Monoit

```
multipass shell control-center
cd ansible-control-center/
provision/common/mmonit_monit.sh
```

3. Install Dcoker and Docker-Compose in observability, dashboard and reverse-proxy

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
multipass shell control-center

ansible-playbook playbooks/k3s/prereq.yml
ansible-playbook playbooks/k3s/setup.yml

multipass exec k3s-master -- sudo cat /etc/rancher/k3s/k3s.yaml > k3s.yaml
IP=$(multipass info "k3s-master" | grep IPv4 | awk '{print $2}')
sed -i '' "s/127.0.0.1/$IP/" k3s.yaml
export KUBECONFIG=$PWD/k3s.yaml

kubectl get nodes
kubectl label nodes k3s-worker kubernetes.io/role=worker

kubectl -n kubernetes-dashboard describe secret admin-user-token | grep '^token'
kubectl proxy

Visit -> http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

```
