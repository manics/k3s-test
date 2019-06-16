#!/bin/sh
set -eu

K3S_VERSION=0.6.0-rc5
K3S_SERVER_FLAGS="--tls-san 192.168.99.100"
LOCAL_PROVISIONER_VERSION=0.0.9
#HELM_VERSION=3.0.0-alpha.1
HELM_VERSION=2.14.1

if [ -f /etc/centos-release ]; then yum install -y -q policycoreutils-python; fi

curl -sfL https://get.k3s.io -o install-k3s.sh
INSTALL_K3S_VERSION=v$K3S_VERSION INSTALL_K3S_EXEC="$K3S_SERVER_FLAGS" sh install-k3s.sh
export PATH=/usr/local/bin:$PATH
while [ `kubectl get nodes -o jsonpath='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' | grep 'Ready=True' | wc -l` -lt 1 ]; do echo -n .; sleep 1; done

# Dynamic storage
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v$LOCAL_PROVISIONER_VERSION/deploy/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Use fixed nodePort for traefik http https
while ! kubectl -n kube-system get svc traefik; do sleep 5; done
kubectl -n kube-system patch svc traefik --type=json -p '[{"op":"replace","path":"/spec/ports/0/nodePort","value":30080},{"op":"replace","path":"/spec/ports/1/nodePort","value":30443}]'

if [ "${HELM_VERSION#3.}" = "$HELM_VERSION" ]; then
  # Helm 2
  curl -sSL https://storage.googleapis.com/kubernetes-helm/helm-v$HELM_VERSION-linux-amd64.tar.gz | tar -xz -C /usr/local/bin/ --strip-components 1 linux-amd64/helm
else
  # Helm 3
  curl -sSL https://get.helm.sh/helm-v$HELM_VERSION-linux-amd64.tar.gz | tar -xz -C /usr/local/bin/ --strip-components 1 linux-amd64/helm
fi
chmod a+x /usr/local/bin/helm

if [ "${HELM_VERSION#3.}" = "$HELM_VERSION" ]; then
  # Helm 2
  helm --kubeconfig /etc/rancher/k3s/k3s.yaml init --service-account tiller
fi

echo export "TERM=${TERM#screen.}" >> /home/vagrant/.bash_profile
cat << EOF > /home/vagrant/.inputrc
"\e[B": history-search-forward
"\e[A": history-search-backward
EOF

# To install Calico instead of flannel
#
# 1. Set:
#    K3S_SERVER_FLAGS="--tls-san 192.168.99.100 --no-flannel"
# 2. After `sh install-k3s.sh` run:
#    curl -sSfLO https://docs.projectcalico.org/v3.7/manifests/calico.yaml
#    sed -i.bak -e 's%192.168.0.0/16%10.42.0.0/16%' calico.yaml
#    kubectl apply -f calico.yaml
#
# Note traefik is currently broken on k3s with Calico
