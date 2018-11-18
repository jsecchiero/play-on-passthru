# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'concurrent'
load 'pci_devices.rb'
load 'usb_devices.rb'

gpu_vm = "test123"

radeon_gpu = get_pci_id('Device','Radeon')
nvidia_gpu = get_pci_id('Vendor','Nvidia').keep_if { |k, v| get_pci_id('Class','VGA').key? k }
amd_gpu = get_pci_id('Vendor','AMD').keep_if { |k, v| get_pci_id('Class','VGA').key? k }

gpus = radeon_gpu.merge(nvidia_gpu).merge(amd_gpu)
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

# Get cpu core available
cpu_ava = Concurrent.physical_processor_count - 1

# Generate libvirt xml compatibile file with all vga and usb detected
cmd_write_xml = "
virt-install                       \
--boot hd                          \
--virt-type kvm                    \
--name #{gpu_vm}                   \
--memory 8192                      \
--cpu host-passthrough             \
--vcpus sockets=1,cores=#{cpu_ava} \
--sound ich6                       \
--video cirrus                     \
--graphics none                    \
--noautoconsole                    \
#{gpus_cmd}                        \
#{usbs_cmd}                        \
--disk $HOME/.vagrant.d/boxes/Microsoft-VAGRANTSLASH-EdgeOnWindows10/1.0/libvirt/boxtest123.img \
--print-xml > #{gpu_vm}.xml
"

system cmd_write_xml


# Change xml header to support qemu custom command
file_name = "#{gpu_vm}.xml"
text = File.read(file_name)
new_contents = text.gsub(/^<domain type="kvm">/, "<domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>")
new_contents = new_contents.gsub(/^  <vcpu>.*$/, "  <vcpu placement='static'>#{cpu_ava}</vcpu>")
puts new_contents
File.open(file_name, "w") {|file| file.puts new_contents }

# Define cpu pin
qemu_cpu = ""
qemu_cpu.concat("  <cputune>\n")
$i = 0
while $i < cpu_ava do
  $ii = $i + 1
  qemu_cpu.concat("    <vcpupin vcpu=\'#{$i}\' cpuset=\'#{$ii}\'/>\n")
  $i += 1
end
qemu_cpu.concat("  </cputune>\n")

# Define pulseaudio
qemu_pulseaudio = <<-eos
  <qemu:commandline>
    <qemu:env name="QEMU_AUDIO_DRV" value="pa"\/>
    <qemu:env name="QEMU_PA_SAMPLES" value="8192"\/>
    <qemu:env name="QEMU_AUDIO_TIMER_PERIOD" value="99"\/>
    <qemu:env name="QEMU_PA_SERVER" value="\/run\/user\/1000\/pulse\/native"\/>
  </qemu:commandline>
</domain>
eos

# Put qemu custom command for pulseaudio support
qemu_custom = ""
qemu_custom.concat(qemu_cpu)
qemu_custom.concat(qemu_pulseaudio)


file_name = "#{gpu_vm}.xml"
text = File.read(file_name)
new_contents = text.gsub(/<\/domain>/, qemu_custom)
puts new_contents
File.open(file_name, "w") {|file| file.puts new_contents }

# define xml to libvirt
cmd_define = "virsh define #{gpu_vm}.xml"
system cmd_define
