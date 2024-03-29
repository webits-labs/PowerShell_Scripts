
  Id CommandLine                                                                                                       
  -- -----------                                                                                                       
   1 Get-PhysicalDisk                                                                                                  
   2 Get-StorageSubSystem                                                                                              
   3 $disks = Get-PhysicalDisk -CanPool $true                                                                          
   4 $disks | sort deviceid                                                                                            
   5 New-StoragePool -FriendlyName testpool -StorageSubSystemFriendlyName "Windows Storage on serv-ssp01" -PhysicalDisks $Disks -ProvisioningTypeDefault Fixed -ResiliencySettingNameDefault parity
   6 Get-StoragePool                                                                                                   
   7 New-VirtualDisk -FriendlyName testdisk -StoragePoolFriendlyName testpool -ProvisioningType Fixed -ResiliencySettingName Parity -PhysicalDiskRedundancy 2 -NumberOfColumns 8 -WriteCacheSize 0mb -UseMaximumSize
   8 Set-MSDSMGlobalDefaultLoadBalancePolicy -Policy RR                                         