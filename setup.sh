# ------------------Step-1-------------------------
swapoff -a
rm /swap.img

# ------------------Step-2-------------------------
# Add net.ipv4.ip_forward=1 if not added
vim /etc/sysctl.conf  
sysctl -p 
# ------------------Step-3--------------------------
# Installing Container Runtime
apt update && apt install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
# Update SystemdCgroup to true in config.toml
sed -i -e "s/SystemdCgroup = false/SystemdCgroup = true/g" /etc/containerd/config.toml
# Restart containerd
systemctl restart containerd

# ------------------Step-4--------------------------
# Installing Kubeadm and kubelete on every nodes
apt install -y apt-transport-https ca-certificates curl gpg
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.37/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.37/deb/ /' > /etc/apt/sources.list.d/kubernetes.list
apt update && apt install -y kubelet kubeadm
apt-mark hold kubelet kubeadm

# ------------------Step-5--------------------------
# On Control Node- Run kubeadm init
kubeadm init
# if required, add the --node-ip=10.0.10.100 to /var/lib/kubelet/kubeadm-flags.env ARGS
systemctl restart kubelet

# ------------------Step-6---------------------------
# ON Host machine or your machine, run below commands to install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
# Copy admin.conf from control-node to host machine
mkdir -p ~/.kube
touch ~/.kube/config
# Copy content from control node- /etc/kubernetes/admin.conf and paste in host machine
vim ~/.kube/config
chmod 600 ~/.kube/config
# Allow 6443 inbound rule to control node from host machine
kubectl cluster-info 
# Above command show cluster details and below command will show all connected nodes.
kubectl get nodes
# You will see only control node connected to cluster.

# ------------------Step-7----------------------------
# Run this on control node
kubeadm token create --print-join-command
# Take the output and run that output as a command in all worker nodes
# Make sure ip forwarding is enabled.
sudo kubeadm join 10.0.2.21:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>


# ------------------Step-8---------------------------
# Installing CNI (clilium) so that our cluster nodes are ready.
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

# ------------------Step-9---------------------------
export KUBECONFIG=/etc/kubernetes/admin.conf
cilium install --version 1.20.1 --set ipam.operator.clusterPoolIPv4PodCIDRList=10.10.0.0/16

# ------------------Step-10---------------------------
# Verify on Host Machine if all services are running and ready
kubectl get nodes -o wide
kubectl -n kube-system get pods -o wide
kubectl get svc -A
