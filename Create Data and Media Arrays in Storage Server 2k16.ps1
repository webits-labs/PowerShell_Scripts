Get-PhysicalDisk | Select-Object FriendlyName, MediaType, Size

<# New-VirtualDisk -FriendlyName "Data_Array" -UseMaximumSize -StoragePoolFriendlyName "Data_Pool" -ProvisioningType Fixed -ResiliencySettingName Parity -NumberOfColumns 4 -Interleave 262144
#>

#Create Data Pool in GUI, then create Tiered Pools using PS:

#Get SSDs to be pooled and set disks to Journal
Get-StoragePool -FriendlyName "Data_Array" | Get-PhysicalDisk | ? MediaType -eq SSD | Set-PhysicalDisk -Usage Journal

#Get HDDs to be pooled
Get-StoragePool -FriendlyName "Data_Array" | Get-PhysicalDisk | ? MediaType -eq HDD

#Create SSD Tier Pool
New-StorageTier -FriendlyName "SSD_Tier" -StoragePoolFriendlyName "Data_Pool" -MediaType SSD

#Create HDD Tier Pool
New-StorageTier -FriendlyName HDD_Tier -StoragePoolFriendlyName "Data_Pool" -MediaType HDD

#Create Data_Array Virtual Disk with 100GB Cache
New-VirtualDisk -FriendlyName "Data_Array" -UseMaximumSize -StoragePoolFriendlyName "Data_Pool" -ProvisioningType Fixed -ResiliencySettingName Parity -NumberOfColumns 4 -Interleave 262144 -WriteCacheSize 100GB


#Create Media_Pool in GUI, then create Media_Array Virtual Disk
New-VirtualDisk -FriendlyName "Media_Array" -UseMaximumSize -StoragePoolFriendlyName "Media_Pool" -ProvisioningType Fixed -ResiliencySettingName Parity -NumberOfColumns 4 -Interleave 262144




