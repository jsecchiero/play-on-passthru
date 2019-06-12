#!/bin/bash

sudo apt-get install -y \
                   gcc pciutils vagrant libusb-1.0-0 git patch  \
                   virt-manager virt-viewer virt-what virt-top  \
                   libvirt-dev libvirt-daemon qemu-system-x86   \
                   qemu-utils

# Ensure qemu runs with your user
sudo sed -i "s/^user = .*$/user = \"${USER}\"/g" /etc/libvirt/qemu.conf

# Vagrant
if [ ! -f /usr/bin/vagrant ]; then
  wget https://releases.hashicorp.com/vagrant/2.1.1/vagrant_2.1.1_x86_64.deb -O /tmp/vagrant.deb
  sudo dpkg -i install /tmp/vagrant.deb
fi

# Download vm
if [ ! -f ~/.vagrant.d/boxes/Microsoft-VAGRANTSLASH-EdgeOnWindows10/1.0/libvirt/box.img ]; then
  vagrant plugin install vagrant-libvirt
  vagrant plugin install vagrant-mutate
  vagrant box add Microsoft/EdgeOnWindows10 --box-version=1.0 && \
  vagrant mutate Microsoft/EdgeOnWindows10 libvirt && \
  qemu-img resize ~/.vagrant.d/boxes/Microsoft-VAGRANTSLASH-EdgeOnWindows10/1.0/libvirt/box.img "+60G"
fi

mkdir ~/.ruby || true
export GEM_HOME=~/.ruby
gem install bundler && \
bundle install      && \
ruby vm.rb
