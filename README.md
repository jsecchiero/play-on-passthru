# play on passthru

This project use official Microsoft Windows10 Vagrant image https://app.vagrantup.com/Microsoft/boxes/EdgeOnWindows10

feature:
- automatically associate each gpu pci to the windows vm
- automatically associate each usb device to the windows vm
- startup the windows vm and play!

## requirements

- cpu feature _VT-d_
- kernel paramenter:
  - modprobe.blacklist=your gpu driver
  - video=efifb:off [optional if another non-pci gpu is available for normal workload es. X11]
  - intel_iommu=on
  - pcie_aspm=off
- kernel module:
  - vfio
  - vfio_iommu_type1
  - vfio_pci
  - ip6_tables
- docker
- check apparmor/selinux

## prepare

**1\. modify this line in /etc/default/grub (disable video output)**  

 _Fedora 27_
```
GRUB_CMDLINE_LINUX="rd.lvm.lv=fedora/root rd.lvm.lv=fedora/swap rhgb quiet modprobe.blacklist=radeon,amdgpu intel_iommu=on  video=efifb:off pcie_aspm=off"
```
_Ubuntu 16.04_
```
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash modprobe.blacklist=radeon,amdgpu intel_iommu=on video=efifb:off pcie_aspm=off"
```

**2\. update grub config**  

_Fedora 27_
```
grub2-mkconfig -o /etc/grub2-efi.cfg
```
_Ubuntu 16.04_
```
update-grub
```

**4\. isolate vga for vfio (use lspci -n for pci ids) /etc/initramfs-tools/modules
```
vfio-pci ids=10de:13c2,10de:0fbb
vfio
vfio_iommu_type1
ip6_tables
```
```
update-grub
```
**4a\. if method above doesn't work use pci-stup as a kernel parameter /etc/initramfs-tools/modules

```
pci-stub.ids=10de:13c2,10de:0fbb
```
```
update-grub
```

**5\. create a policy for selinux/apparmor or for test disable it**  

_Fedora 27_  

editing this line /etc/selinux/config
```
SELINUX=disabled
```
_Ubuntu 16.04_
```
service apparmor stop
service apparmor teardown
update-rc.d -f apparmor remove
apt-get remove apparmor
```


**6\. install docker**  
```
export CHANNEL=stable
curl -fsSL get.docker.com -o get-docker.sh
sh get-docker.sh
systemctl enable docker
systemctl start docker
```

**7\. reboot to make those changes effective**  
```
reboot
```

## usage

```
sudo bash ./run.sh
```
