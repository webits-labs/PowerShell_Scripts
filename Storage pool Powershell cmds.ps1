Okay I create another testpool, which is the following:

Code:
FriendlyName      MediaType        UniqueId                     Size
------------------------------------------------------------------------
ATA Samsung SSD 850  SSD  5002538D419297C1                  249913409536
ATA Samsung SSD 850  SSD  5002538DA031F6B1                  249913409536
ATA Samsung SSD 850  SSD  5002538DA017C4D8                  249913409536
Msft Virtual Disk    HDD  60022480133D913F3C6B17B3A35A167C  107374182400
Msft Virtual Disk    HDD  60022480C6DE23EE81DBA865EC7635B4  107374182400
Msft Virtual Disk    HDD  60022480168FFB60CE2799878575BE74  107374182400
Msft Virtual Disk    HDD  60022480557AB628186FD1BFB4F4F910  107374182400
Basically the pool consists out ou 3 Samsung SSDs with 250GB space and 4 virtual disks with 100GB space each.


Then I created two storage tiers and the virtual disk creating the tiered parity space:

Code:
$ssd_Tier = New-StorageTier -StoragePoolFriendlyName StoragePool0 -FriendlyName SSD_Tier -MediaType SSD -ResiliencySettingName Parity -NumberOfColumns 3
$hdd_Tier = New-StorageTier -StoragePoolFriendlyName StoragePool0 -FriendlyName HDD_Tier -MediaType HDD -ResiliencySettingName Parity -NumberOfColumns 4

New-VirtualDisk -StoragePoolFriendlyName StoragePool0 -FriendlyName TieredParitySpace -StorageTiers @($ssd_tier, $hdd_tier) -storagetiersizes 100GB, 200GB -ResiliencySettingName Parity -WriteCacheSize 25GB


Apparently the commands finished without errors and reporting that output:
Code:
FriendlyName  ResiliencySettingName  OperationalStatus  HealthStatus  IsManualAttach  Size
-------------------------------------------------------------------------------------------
TieredParitySpace                          OK             Healthy         False      300 GB

1. So now the question if this is correct and I could check if its on parity?
2. What would be normal way when I have to change a drive in cases of failure?
3. What would be the maximum sizes for a setup of SSD-Tier: 3x250GB and HDD-Tier: 6x8TB and a WriteBackCache of 50GB?