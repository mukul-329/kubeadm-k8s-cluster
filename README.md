# Kubernetes Cluster Installation with kubeadm using Ansible

This project automates the installation of a Kubernetes cluster using **kubeadm** and **Ansible** on Linux/Ubuntu nodes, including Kubernetes prerequisites, container runtime, control-plane initialization, worker joining, Cilium CNI, kubectl, kubeconfig, and validation.

> Example versions used in this project: Kubernetes **v1.37**, Cilium **v1.20.1**, Pod CIDR **10.10.0.0/16**.

## Architecture
```text
                 Ansible Control Node
                         |
                         | SSH
          +--------------+--------------+
          |              |              |
          v              v              v
   +-------------+ +-------------+ +-------------+
   | Control     | | Worker 1    | | Worker 2    |
   | Plane       | |             | |             |
   | kubeadm     | | kubelet     | | kubelet     |
   | API Server  | | Cilium      | | Cilium      |
   | etcd        | |             | |             |
   +-------------+ +-------------+ +-------------+
                         |
                    Cilium CNI
                    Pod Network
```

Ansible uses an inventory to organize managed hosts and YAML playbooks to automate configuration. Kubernetes `kubeadm` is designed to bootstrap Kubernetes clusters and can be integrated with automation systems such as Ansible or Terraform. [Kubernetes kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/) | [Ansible Playbooks](https://docs.ansible.com/projects/ansible/latest/getting_started/get_started_playbook.html)

---

## 1. Prerequisites

### Ansible Control Node

Install Ansible and verify:

```bash
sudo apt update && apt install -y ansible
ansible --version
```

Test access to the Kubernetes nodes:

```bash
ansible kube_cluster -i inventory.ini -m ping
```

Expected:

```text
SUCCESS
"ping": "pong"
```

### Kubernetes Nodes

Recommended minimum requirements include:
- Linux operating system
- At least 2 GiB RAM per machine
- At least 2 CPUs for the control-plane machine
- Network connectivity between all cluster nodes
- Compatible container runtime
- Compatible `kubeadm`, `kubelet`, and Kubernetes versions

See the official [Kubernetes kubeadm prerequisites](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/).

---

## 2. AWS Networking

For an AWS deployment, make sure the instances can communicate through:

- VPC routing
- Security Groups
- Network ACLs, if used

Common ports:

| Port | Protocol | Purpose |
|---|---|---|
| 22 | TCP | SSH / Ansible |
| 6443 | TCP | Kubernetes API server |
| 2379-2380 | TCP | etcd |
| 10250 | TCP | Kubelet API |
| 10257 | TCP | kube-controller-manager |
| 10259 | TCP | kube-scheduler |

Restrict Security Group sources to trusted CIDRs instead of exposing Kubernetes ports to the internet.

---

## 3. Project Structure

Example:

```text
kubeadm-k8s-cluster/
│
├── ansible-setup/
│   ├── inventory/
|       ├──hosts.ini
│   ├── k8-access.yml
│   ├── main.yml
│   ├── roles/
│   │   ├── common/
│   │   ├── container-runtime/
│   │   ├── kubernetes/
│   │   ├── control-plane/
│   │   ├── worker/
│   │   ├── cilium/
│   │   └── kubectl/
│   └── group_vars/
│       └── all.yml
└── README.md
```

The exact role layout can be changed according to the project structure.

---

# Kubernetes Installation Flow

```text
Prepare all nodes
       |
       v
Configure kernel / disable swap
       |
       v
Install container runtime
       |
       v
Install kubeadm / kubelet / kubectl
       |
       v
Initialize control plane
       |
       v
Configure kubeconfig
       |
       v
Generate worker join command
       |
       v
Join workers
       |
       v
Install Cilium CNI
       |
       v
Configure kubectl
       |
       v
Validate cluster
```

---

## Networking

```text
TCP 22
   |
   +--> SSH / Ansible

TCP 6443
   |
   +--> kubectl --> Kubernetes API Server

TCP 10250
   |
   +--> Kubernetes components --> kubelet

10.10.0.0/16
   |
   +--> Cilium Pod network
```

---

# References

- [Kubernetes - Creating a cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
- [Kubernetes - Installing kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
- [Kubernetes - Bootstrapping clusters with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
- [Ansible - Getting Started](https://docs.ansible.com/projects/ansible/latest/getting_started/index.html)
- [Ansible - Inventory](https://docs.ansible.com/projects/ansible/latest/inventory_guide/intro_inventory.html)
- [Ansible - Playbooks](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks.html)

---

## Conclusion

This project automates a kubeadm-based Kubernetes cluster using Ansible.

It demonstrates the complete flow from:

```text
Linux nodes
    ↓
Ansible
    ↓
Container Runtime
    ↓
kubeadm
    ↓
Control Plane
    ↓
Worker Nodes
    ↓
Cilium
    ↓
kubectl
    ↓
Ready Kubernetes Cluster
```

The project is useful for learning how **Ansible automation, Kubernetes bootstrapping, CNI networking, kubeconfig management, and AWS networking** work together.
