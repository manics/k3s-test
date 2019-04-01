# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"

  config.vm.network "forwarded_port", guest: 6443, host: 26443
  config.vm.network "forwarded_port", guest: 443, host: 20443
  config.vm.network "forwarded_port", guest: 80, host: 20080

  # config.vm.synced_folder "../data", "/vagrant_data"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "3172"
    vb.cpus = 3
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -eu
    curl -sfL https://get.k3s.io -o install-k3s.sh
    yum install -y -q policycoreutils-python
    sh install-k3s.sh
    while [ `/usr/local/bin/k3s kubectl get nodes -o jsonpath='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' | grep 'Ready=True' | wc -l` -lt 1 ]; do echo -n .; sleep 1; done
  SHELL
end
