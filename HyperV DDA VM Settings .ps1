Set-VM -GuestControlledCacheTypes $true -vmName ddatest2

Set-VM -LowMemoryMappedIoSpace 3GB -vmname ddatest2

Set-VM -HighMemoryMappedIoSpace 33280Mb -vmname ddatest2



PCIROOT(0)#PCI(0101)#PCI(0000) # Graphics Device PT #1

$locationpath = 'PCIROOT(0)#PCI(0101)#PCI(0000)'

Dismount-VMHostAssignableDevice -force -LocationPath $locationpath

Add-VMAssignableDevice -LocationPath $locationpath -vmname ddatest2
