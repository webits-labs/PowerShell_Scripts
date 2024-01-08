#Variables
    $storage=Get-StorageSubSystem
    $PoolName="Mirror Data Pool"
    $VDiskName="Mirror Data Disk"
    $SSD=Get-StorageTier -FriendlyName SSDTier
    $HDD=Get-StorageTier -FriendlyName HDDTier

# Verify disks do not show up as "Unknown"
    Get-StoragePool $PoolName | Get-PhysicalDisk | FT Friendlyname, Size, MediaType
# Fix disks showing as "Unknown"
    get-storagepool $PoolName | Get-PhysicalDisk | ? MediaType -EQ "UnSpecified" | Set-PhysicalDisk -MediaType HDD

#0 Enable MPIO Policy
    Get-MSDSMGlobalDefaultLoadBalancePolicy
    Set-MSDSMGlobalDefaultLoadBalancePolicy -policy lb
   #Regedit -> HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\msdsm\Parameters -> Add 2 parameters from Petri.com -> Reboot


#1 Create Storage Pool
    New-StoragePool 
                    -StorageSubSystemUniqueId $storage.UniqueId 
                    -FriendlyName $PoolName 
                    -PhysicalDisks (Get-PhysicalDisk -CanPool $true) 
                    -LogicalSectorSizeDefault 512 
                    -FaultDomainAwarenessDefault PhysicalDisk
    
    New-StoragePool -StorageSubSystemUniqueId $storage.UniqueId -FriendlyName $PoolName -PhysicalDisks (Get-PhysicalDisk -CanPool $true) -FaultDomainAwarenessDefault PhysicalDisk


    
#2 Set default columns per Array type:
    Get-StoragePool $PoolName | Set-ResiliencySetting -name Simple -NumberOfColumnsDefault 1
    Get-StoragePool $PoolName | Set-ResiliencySetting -name Mirror -NumberOfColumnsDefault 2
    Get-StoragePool $PoolName | Set-ResiliencySetting -name Parity -NumberOfColumnsDefault 3
  
   # Verify Default Columns changed successfully:
    Get-StoragePool $PoolName | Get-ResiliencySetting
         
#3.1 Create Storage Tiers
    New-StorageTier -StoragePoolFriendlyName $PoolName -FriendlyName SSDTier -MediaType SSD -ResiliencySettingName Simple -NumberOfColumns 1
    New-StorageTier -StoragePoolFriendlyName $PoolName -FriendlyName HDDTier -MediaType HDD -ResiliencySettingName Parity -NumberOfColumns 3
   
    # Get-StoragePool $poolname | New-StorageTier -FriendlyName HDDTier -MediaType HDD
   
   # Verify Storage Tiers created successfully:
    Get-StorageTier -FriendlyName SSDTier
    Get-StorageTier -FriendlyName HDDTier
    
#3.2 Create Storage Tiered Volume
    New-Volume -StoragePoolFriendlyName $PoolName -FriendlyName $VDiskName -FileSystem ReFS -StorageTierFriendlyNames SSDTier, HDDTier -StorageTierSizes 100GB, 3.5TB
    New-Volume -StoragePoolFriendlyName $PoolName -FriendlyName $VDiskName -FileSystem ReFS -StorageTierFriendlyNames SSDTier, HDDTier -StorageTierSizes 100GB, 3.5TB -AllocationUnitSize 65536  -ProvisioningType Fixed

  
#4.1 Create virtual disk
    New-VirtualDisk 
                    -StoragePoolFriendlyName $PoolName
                    -FriendlyName $VDiskName 
                    -ResiliencySettingName Parity 
                    -UseMaximumSize 
                  # -WriteCacheSize 100GB
        
    New-VirtualDisk -StoragePoolFriendlyName $PoolName -FriendlyName $VDiskName -ResiliencySettingName Mirror -UseMaximumSize -WriteCacheSize 75GB

#4.2 Create Storage Tiered Volume
    New-Volume -StoragePoolFriendlyName $PoolName -FriendlyName $VDiskName -FileSystem ReFS -AllocationUnitSize 65536 -DriveLetter P -UseMaximumSize


#5 Set Power Protected True
    Set-StoragePool -FriendlyName $PoolName -IsPowerProtected $False
   

# Getting Information

    Get-VirtualDisk
                   -FriendlyName $VDiskName | select-object WriteCacheSize

    Get-VirtualDisk -FriendlyName $VDiskName | select-object WriteCacheSize
    
    Get-StoragePool $poolname

# Cleanup
    Remove-StoragePool -FriendlyName $PoolName
        


<#Create Storage Tiered Virtual Disk
    New-VirtualDisk  
                    -FriendlyName $VDiskName
                    -StorageTiers $SSD, $HDD
                    -StorageTierSizes 100GB, 3.5TB
                    -UseMaximumSize

    New-VirtualDisk -StoragePoolFriendlyName $PoolName -FriendlyName $VDiskName -StorageTiers $SSD, $HDD -storagetiersizes 100GB, 3.5TB -ResiliencySettingName Parity
    
    #>        

