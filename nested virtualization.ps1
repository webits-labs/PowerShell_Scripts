#Check if Nested Virtualization is enabled 
cat /sys/module/kvm_intel/parameters/nested

#Enable Nested Virtualization on Intel (Replace Intel with AMD for AMD)
modprobe -r kvm_intel
modprobe kvm_intel nested=1

#Pass through physical disk to Virtual Machine
/dev/disk/by-id/ata-INTEL_SSDSA2BW160G3H_CVPR14030839160DGN

#Set CPU to "Custom" type and append line below in XML:
</features>
  <cpu mode='host-model' check='partial'>
    <model fallback='allow'/>

# OLD -> <feature policy='require' name='vmx'/>

#Replace UUID if booting from previously licensed OS
#UUID to replace:   <uuid>1d9f5cce-877a-ce25-8461-62cffdf784ae</uuid>
#UUID to replace with: 031B021C-040D-056C-4406-110700080009

#Sources:
[2] https://stafwag.github.io/blog/blog/2018/06/04/nested-virtualization-in-kvm/
[1] https://forums.unraid.net/topic/70040-guide-vms-in-vm-intel-nested-virtualization/



Docker Recovery
Nested VM for HDD Passthrough of Docker lab Env for migration purposes
/dev/disk/by-id/ata-INTEL_SSDSA2BW160G3H_CVPR14030839160DGN