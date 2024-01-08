# GPU Disable

(Get-PnpDevice -PresentOnly).where{ $_.InstanceID -like '*VEN_1002*' } # Get AMD Radeon Instance ID

$vmname = 'ddatest'
$instanceID = PCI\VEN_1002...
$locationpath = 'PCIROOT(0)#PCI(0300)#PCI(0000)'

Dismount-VMHostAssignableDevice -LocationPath $locationpath -Force -verbose

