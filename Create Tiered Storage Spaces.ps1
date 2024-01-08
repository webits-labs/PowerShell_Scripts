
# ----Original----


# First create your storage pool
New-StoragePool -StoragePoolFriendlyName "Pool1" -StorageSubSystemFriendlyName (Get-StorageSubSystem).FriendlyName -PhysicalDisks (Get-PhysicalDisk -CanPool $true) -LogicalSectorSizeDefault 512 -FaultDomainAwarenessDefault PhysicalDisk

# Next we set the resiliency settings
Get-Storagepool Pool1 | Set-ResiliencySetting -Name Mirror -NumberOfColumnsDefault 1
Get-Storagepool Pool1 | Set-ResiliencySetting -Name Parity -NumberOfColumnsDefault 3

# Now we create our storage tiers. One SSD, one HDD
New-StorageTier -StoragePoolFriendlyName Pool1 -FriendlyName SSDTier -MediaType SSD -ResiliencySettingName Mirror -NumberOfColumns 1 -PhysicalDiskRedundancy 1 -FaultDomainAwareness PhysicalDisk

New-StorageTier -StoragePoolFriendlyName Pool1 -FriendlyName HDDTier -MediaType HDD -ResiliencySettingName Parity -NumberOfColumns 3 -PhysicalDiskRedundancy 1 -FaultDomainAwareness PhysicalDisk

# create our Volume
New-Volume -StoragePoolFriendlyName Pool1 -FriendlyName VM -FileSystem ReFS -StorageTierFriendlyName SSDTier, HDDTier -StorageTierSizes 200GB, 3.5TB

# make sure that it actually formatted properly
Get-StorageTier | FT FriendlyName, ResiliencySettingName, PhysicalDiskRedundancy, FaultDomainAwareness, NumberOfDataCopies

# I know that I still have space. So how do we expand?
Resize-StorageTier -InputObject (Get-StorageTier -FriendlyName "VM_HDDTier") -Size 3.6TB

# If on a UPS we run this
Set-StoragePool -FriendlyName Pool1 -IsPowerProtected $True


# ----Original----



# ----Modified----


# First create your storage pool
New-StoragePool -StoragePoolFriendlyName "Plex Pool" -StorageSubSystemFriendlyName (Get-StorageSubSystem).FriendlyName -PhysicalDisks (Get-PhysicalDisk -CanPool $true) -LogicalSectorSizeDefault 512 -FaultDomainAwarenessDefault PhysicalDisk

# Next we set the resiliency settings
Get-Storagepool Pool1 | Set-ResiliencySetting -Name Mirror -NumberOfColumnsDefault 1
Get-Storagepool "Plex Pool" | Set-ResiliencySetting -Name Parity -NumberOfColumnsDefault 3

# Now we create our storage tiers. One SSD, one HDD
New-StorageTier -StoragePoolFriendlyName "Plex Pool" -FriendlyName SSDTier -MediaType SSD -ResiliencySettingName Simple -FaultDomainAwareness PhysicalDisk

New-StorageTier -StoragePoolFriendlyName "Plex Pool" -FriendlyName HDDTier -MediaType HDD -ResiliencySettingName Parity -NumberOfColumns 4 -PhysicalDiskRedundancy 1 -FaultDomainAwareness PhysicalDisk

# create our Volume
New-Volume -StoragePoolFriendlyName "Plex Pool" -FriendlyName "Plex Media" -FileSystem ReFS -StorageTierFriendlyName SSDTier, HDDTier -StorageTierSizes 155GB, 3.5TB

# make sure that it actually formatted properly
Get-StorageTier | FT FriendlyName, ResiliencySettingName, PhysicalDiskRedundancy, FaultDomainAwareness, NumberOfDataCopies

# I know that I still have space. So how do we expand?
Resize-StorageTier -InputObject (Get-StorageTier -FriendlyName "VM_HDDTier") -Size 3.6TB

# If on a UPS we run this
Set-StoragePool -FriendlyName "Plex Pool" -IsPowerProtected $True