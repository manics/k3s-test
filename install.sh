#!/bin/sh
# Based on
# https://github.com/jupyterhub/zero-to-jupyterhub-k8s/blob/08c13609c1d0c6cb07d45d49d0a876100cf941eb/ci/common

set -eux

K3S_VERSION=v1.19.2+k3s1
HELM_VERSION=v3.3.4
IP_ADDRESS=`ip -o -4 addr show eth0 | awk '{print $4}' | cut -d/ -f1`
# If set to 1 use docker, otherwise use containerd
# https://rancher.com/docs/k3s/latest/en/advanced/#using-docker-as-the-container-runtime
DOCKER=
K3S_SERVER_FLAGS=

if [ "${DOCKER}" = "1" -a ! -x /usr/bin/docker ]; then
  curl -sf https://releases.rancher.com/install-docker/19.03.sh | sh -s
  K3S_SERVER_FLAGS=--docker
  # v1.19.2+k3s1 fails
  K3S_VERSION=v1.18.9+k3s1
fi

if [ -f /etc/centos-release ]; then
  # https://rancher.com/docs/k3s/latest/en/advanced/#experimental-selinux-support
  yum install -y -q \
    policycoreutils-python \
    container-selinux selinux-policy-base \
    https://rpm.rancher.io/k3s-selinux-0.1.1-rc1.el7.noarch.rpm
fi

# Disable the K3s Network Policy controller, install calico instead
curl -sfL https://get.k3s.io | \
  INSTALL_K3S_VERSION=${K3S_VERSION} sh -s - \
  --tls-san ${IP_ADDRESS} \
  --write-kubeconfig-mode=644 \
  --disable metrics-server \
  --disable traefik \
  --disable-network-policy \
  --flannel-backend=none \
  ${K3S_SERVER_FLAGS}

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
export PATH=/usr/local/bin:$PATH

# Calico as CNI for full NetworkPolicy support
curl -sfL https://docs.projectcalico.org/v3.14/manifests/calico.yaml \
  | sed '/"type": "calico"/a\
    "container_settings": {\
      "allow_ip_forwarding": true\
    },' \
  | kubectl apply -f -

# Wait for Calico and CoreDNS
kubectl rollout status --watch --timeout 300s daemonset/calico-node -n kube-system
kubectl rollout status --watch --timeout 300s deployment/calico-kube-controllers -n kube-system
kubectl rollout status --watch --timeout 300s deployment/coredns -n kube-system

# Install Helm
curl -sf https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | DESIRED_VERSION=${HELM_VERSION} bash

# Create a kubeconfig with the external IP
sed s/127.0.0.1/${IP_ADDRESS}/ /etc/rancher/k3s/k3s.yaml > /etc/rancher/k3s/k3s-ext.yaml

# Use fixed nodePort for traefik http https
# while ! kubectl -n kube-system get svc traefik; do sleep 5; done
# kubectl -n kube-system patch svc traefik --type=json -p '[{"op":"replace","path":"/spec/ports/0/nodePort","value":30080},{"op":"replace","path":"/spec/ports/1/nodePort","value":30443}]'

# Local customisations for vagrant user
echo export "TERM=${TERM#screen.}" >> /home/vagrant/.bash_profile
cat << EOF > /home/vagrant/.inputrc
"\e[B": history-search-forward
"\e[A": history-search-backward
EOF

chown vagrant:vagrant /home/vagrant/.bash_profile /home/vagrant/.inputrc

echo "Run"
echo "vagrant ssh -- sudo cat /etc/rancher/k3s/k3s-ext.yaml > k3s.yaml"
echo "to fetch the kubeconfig file"
