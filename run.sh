#!/bin/bash

apt-get install -y libvirt-bin libvirt-dev libvirt-daemon libusb-1.0-0-dev      \
                   ruby-dev gcc pciutils vagrant libusb-1.0-0 git patch         \
                   libpixman-1-dev zlib1g-dev libspice-protocol-dev libfdt-dev  \
                   libaio-dev libcap-dev libiscsi-dev libpulse-dev qemu-utils   \
                   virt-manager virt-viewer virt-what virt-top                  \
                   libspice-server-dev libusbredirhost-dev

# Build Qemu hda working version
if [ ! -f /opt/qemu-2.11.1/build/x86_64-softmmu/qemu-system-x86_64 ]; then
  OLDPATH=$(pwd)
  cd /opt && \
  curl -O https://download.qemu.org/qemu-2.11.1.tar.xz && \
  tar xvf qemu-2.11.1.tar.xz && \
  cd qemu-2.11.1 && \
  curl -O https://gist.githubusercontent.com/spheenik/8140a4405f819c5cd2465a65c8bb6d09/raw/9735bcfaaaef45cf47e1b5d92c5006adf6ecd737/v1.patch && \
  patch -p0 < v1.patch && \
  mkdir build || true && \
  cd build && \
  ../configure --prefix=/opt/qemu-test --python=/usr/bin/python2 --target-list=x86_64-softmmu --audio-drv-list=pa --disable-werror && \
  sed -i "s/^user =.*/user = \"$SUDO_USER\"/g" /etc/libvirt/qemu.conf
  ln -s /opt/qemu-2.11.1/build/x86_64-softmmu/qemu-system-x86_64 /usr/local/bin/qemu-system-x86_64
  ln -s /opt/qemu-2.11.1/build/qemu-img /usr/local/bin/qemu-img
  make
  cd $OLDPATH
fi

# Vagrant
if [ ! -f /usr/bin/vagrant ]; then
  wget https://releases.hashicorp.com/vagrant/2.1.1/vagrant_2.1.1_x86_64.deb -O /tmp/vagrant.deb
  dpkg -i install /tmp/vagrant.deb
fi

# Download vm
if [ ! -f ~/.vagrant.d/boxes/Microsoft-VAGRANTSLASH-EdgeOnWindows10/1.0/libvirt/box.img ]; then
  vagrant plugin install vagrant-libvirt
  vagrant plugin install vagrant-mutate
  vagrant box add Microsoft/EdgeOnWindows10 --box-version=1.0 && \
  vagrant mutate Microsoft/EdgeOnWindows10 libvirt && \
  /opt/qemu-2.11.1/build/qemu-img resize ~/.vagrant.d/boxes/Microsoft-VAGRANTSLASH-EdgeOnWindows10/1.0/libvirt/box.img +60G
fi

gem install bundler && \
bundle install      && \
ruby vm.rb
