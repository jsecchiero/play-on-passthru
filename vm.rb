# -*- mode: ruby -*-
# vi: set ft=ruby :

load 'pci_devices.rb'
load 'usb_devices.rb'

amd_gpu = get_pci_id('Device','Radeon')
nvidia_gpu = get_pci_id('Vendor','Nvidia').keep_if { |k, v| get_pci_id('Class','VGA').key? k }

gpus = amd_gpu.merge(nvidia_gpu)
gpus_cmd = ""
gpus.each_key do |pci_id|
  bus = pci_id.split(':')[0]
  slot = pci_id.split(':')[1]
  gpus_cmd="#{gpus_cmd} --host-device #{bus}:#{slot}.0 --host-device #{bus}:#{slot}.1"
end

my_usb = USB.new
usbs = my_usb.show_ids
usbs_cmd = ""
usbs.each do |usb|
  vendor = usb.split(':')[0]
  product = usb.split(':')[1]
  if vendor == "8087" or vendor == "1d6b"
    next
  end
  usbs_cmd = "#{usbs_cmd} --host-device 0x#{vendor}:0x#{product}"
end

cmd = "
       virt-install    \
       --boot hd       \
       --virt-type kvm \
       --name gpu-vm   \
       --memory 8192   \
       --cpu host      \
       --vcpus 4       \
       #{gpus_cmd}     \
       #{usbs_cmd}     \
       --disk $HOME/.vagrant.d/boxes/Microsoft-VAGRANTSLASH-EdgeOnWindows10/1.0/libvirt/box.img 
      "

print cmd
system cmd
