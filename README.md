# K3OS Vagrant

Vagantfile for [K3OS](https://github.com/rancher/k3os).

This Vagrantfile uses [this libvirt box](https://app.vagrantup.com/manics/boxes/k3os).

Vagrant cannot detect the operating system so you must run `vagrant provision` yourself.
This will replace the default K3S network plugin with Calico, and also copy your `~/.ssh/id_rsa.pub` into the VM so that you can ssh directly.

    vagrant up
    vagrant provision

To obtain a kube-config file containing the VMs external IP:

    vagrant ssh -- cat /etc/rancher/k3s/k3s-ext.yaml > k3s.yaml
