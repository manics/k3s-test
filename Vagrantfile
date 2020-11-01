# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "manics/k3os"
  config.vm.box_version = "0.11.1"

  # config.vm.network "forwarded_port", guest: 80, host: 8080
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"
  # config.vm.synced_folder "../data", "/vagrant_data"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
    vb.cpus = 3
  end
  config.vm.provider "libvirt" do |lv|
    lv.memory = "4096"
    lv.cpus = 3
  end


  # config.vm.provision "file" doesn't work because vagrant doesn't recognise the base OS
  config.vm.provision "shell" do |s|
    # https://stackoverflow.com/a/31153912
    ssh_pub_key = File.readlines("#{Dir.home}/.ssh/id_rsa.pub").first.strip

    # Default location is not executable
    s.upload_path = '/home/rancher/vagrant-shell'

    s.inline = <<-SHELL
set -eu

# See https://github.com/rancher/k3os#sample-configyaml
# For K3OS configuration
K3OS_CONFIG=/var/lib/rancher/k3os/config.yaml
if [ -f $K3OS_CONFIG ]; then
  echo $K3OS_CONFIG exists, skipping
else
  cat << EOF > /var/lib/rancher/k3os/config.yaml
k3os:
  # Disable default network plugin because we'll use Calico instead
  k3s_args:
    - server
    - --disable-network-policy
    - --flannel-backend=none
run_cmd:
  # Create a kubeconfig with the external IP
  - sed s/127.0.0.1/`ip -o -4 addr show eth0 | awk '{print $4}' | cut -d/ -f1`/ /etc/rancher/k3s/k3s.yaml > /etc/rancher/k3s/k3s-ext.yaml
EOF
  k3os config
fi

# TODO: Could do this config.yaml
CALICO_MANIFEST=/var/lib/rancher/k3s/server/manifests/calico.yaml
if [ -f $CALICO_MANIFEST ]; then
  echo $CALICO_MANIFEST exists, skipping
else
  # Indentation in the sed replacement is important
  curl -sfL https://docs.projectcalico.org/v3.16/manifests/calico.yaml \\
  | sed '/"type": "calico"/a\\
          "container_settings": {\\
            "allow_ip_forwarding": true\\
          },' > $CALICO_MANIFEST

  # Wait for k3s to detect the new manifest
  sleep 20s
  kubectl rollout status --watch --timeout 300s daemonset/calico-node -n kube-system
  kubectl rollout status --watch --timeout 300s deployment/calico-kube-controllers -n kube-system
  kubectl rollout status --watch --timeout 300s deployment/coredns -n kube-system
fi
echo #{ssh_pub_key} >> /home/rancher/.ssh/authorized_keys

echo "Run"
echo "vagrant ssh -- cat /etc/rancher/k3s/k3s-ext.yaml > k3s.yaml"
echo "to fetch the kubeconfig file"

    SHELL
  end

end

# WARNING: https://github.com/vagrant-libvirt/vagrant-libvirt/issues/85
# `vagrant box remove` does not delete the old image and `vagrant box add`
# will not overwrite the old image. To delete it:
# `virsh vol-list default`, `virsh vol-delete --pool default <name>.img`
# -*- mode: ruby -*-
# vi: set ft=ruby :
