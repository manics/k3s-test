# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # centos/8 not yet supported by K3s
  config.vm.box = "centos/7"
  #config.vm.box = "ubuntu/bionic64"
  config.vm.hostname = "k3s"

  config.vm.network "forwarded_port", guest: 6443, host: 6443
  config.vm.network "forwarded_port", guest: 443, host: 20443
  config.vm.network "forwarded_port", guest: 80, host: 20080

  # This matches the default minikube IP
  # config.vm.network "private_network", ip: "192.168.99.100"

  # config.vm.synced_folder "../data", "/vagrant_data"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "3172"
    vb.cpus = 3
  end
  config.vm.provider "libvirt" do |lv|
    lv.memory = "3172"
    lv.cpus = 3
  end

  config.vm.provision "shell",
    path: "install.sh"

  # https://stackoverflow.com/a/31153912
  config.vm.provision "shell" do |s|
    ssh_pub_key = File.readlines("#{Dir.home}/.ssh/id_rsa.pub").first.strip
    s.inline = <<-SHELL
      echo #{ssh_pub_key} >> /home/vagrant/.ssh/authorized_keys
    SHELL
  end
end
