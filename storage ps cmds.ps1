Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

PS C:\Users\Administrator> get-storagepool test.pool |Get-PhysicalDisk | FT friendlyname, size, mediatype
get-storagepool : No MSFT_StoragePool objects found with property 'FriendlyName' equal to 'test.pool'.  Verify the
value of the property and retry.
At line:1 char:1
+ get-storagepool test.pool |Get-PhysicalDisk | FT friendlyname, size,  ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : ObjectNotFound: (test.pool:String) [Get-StoragePool], CimJobException
    + FullyQualifiedErrorId : CmdletizationQuery_NotFound_FriendlyName,Get-StoragePool

PS C:\Users\Administrator> get-storagepool test |Get-PhysicalDisk | FT friendlyname, size, mediatype

friendlyname                  size MediaType
------------                  ---- ---------
WDC WD5000AAKS-00TMA0 500107862016 Unspecified
ST9500420AS           500107862016 HDD


PS C:\Users\Administrator> get-storagepool test |Get-PhysicalDisk | where mediatype -eq "Unspecified" |set-physicaldisk -mediatype HDD
PS C:\Users\Administrator> get-storagepool test |Get-PhysicalDisk | FT friendlyname, size, mediatype

friendlyname                  size MediaType
------------                  ---- ---------
WDC WD5000AAKS-00TMA0 500107862016 HDD
ST9500420AS           500107862016 HDD


PS C:\Users\Administrator> get-storagepool test |Get-ResiliencySetting

Name   NumberOfDataCopies FaultDomainRedundancy NumberOfColumns Interleave NumberOfGroups
----   ------------------ --------------------- --------------- ---------- --------------
Simple 1                  0                     Auto            262144     1
Mirror 2                  1                     Auto            262144     1
Parity 1                  1                     Auto            262144     Auto


PS C:\Users\Administrator> get-storagepool test |Get-PhysicalDisk | FT friendlyname, size, mediatype

friendlyname                  size MediaType
------------                  ---- ---------
WDC WD5000AAKS-00TMA0 500107862016 Unspecified
ST9500420AS           500107862016 HDD


PS C:\Users\Administrator> get-storagepool test |Get-PhysicalDisk | where mediatype -eq "Unspecified" |set-physicaldisk -mediatype HDD
PS C:\Users\Administrator> get-storagepool test |Get-PhysicalDisk | FT friendlyname, size, mediatype

friendlyname                  size MediaType
------------                  ---- ---------
WDC WD5000AAKS-00TMA0 500107862016 HDD
ST9500420AS           500107862016 HDD


PS C:\Users\Administrator>

PS C:\Users\Administrator> get-storagepool test |Get-ResiliencySetting

Name   NumberOfDataCopies FaultDomainRedundancy NumberOfColumns Interleave NumberOfGroups
----   ------------------ --------------------- --------------- ---------- --------------
Simple 1                  0                     Auto            262144     1
Mirror 2                  1                     Auto            262144     1
Parity 1                  1                     Auto            262144     Auto


PS C:\Users\Administrator> get-storagepool test |set-ResiliencySetting -name Parity -NumberOfColumnsDefault 3
PS C:\Users\Administrator> get-storagepool test |Get-ResiliencySetting

Name   NumberOfDataCopies FaultDomainRedundancy NumberOfColumns Interleave NumberOfGroups
----   ------------------ --------------------- --------------- ---------- --------------
Simple 1                  0                     Auto            262144     1
Mirror 2                  1                     Auto            262144     1
Parity 1                  1                     3               262144     Auto


PS C:\Users\Administrator>

PS C:\Users\Administrator> get-virtualdisk

FriendlyName ResiliencySettingName FaultDomainRedundancy OperationalStatus HealthStatus    Size FootprintOnPool Storage
                                                                                                                Efficie
                                                                                                                    ncy
------------ --------------------- --------------------- ----------------- ------------    ---- --------------- -------
test         Simple                0                     OK                Healthy      1.36 TB         1.36 TB 100.00%



PS C:\Users\Administrator> get-virtualdisk | ft numberofcolumns

numberofcolumns
---------------
              3


PS C:\Users\Administrator> get-virtualdisk | ft friendlyname, resiliencysettingname, numberofcolumns

friendlyname resiliencysettingname numberofcolumns
------------ --------------------- ---------------
test         Simple                              3


PS C:\Users\Administrator>

PS C:\Users\Administrator> new-virtualdisk -FriendlyName test -StoragePoolFriendlyName test -size 10gb -ProvisioningType
 fixed -PhysicalDiskRedundancy 1

FriendlyName ResiliencySettingName FaultDomainRedundancy OperationalStatus HealthStatus  Size FootprintOnPool StorageEf
                                                                                                               ficiency
------------ --------------------- --------------------- ----------------- ------------  ---- --------------- ---------
test         Mirror                1                     OK                Healthy      10 GB           22 GB    45.45%


PS C:\Users\Administrator> new-virtualdisk -FriendlyName test -StoragePoolFriendlyName test -size 10gb -ProvisioningType fixed -PhysicalDiskRedundancy 2
new-virtualdisk : Not Supported

Extended information:
The storage pool does not have sufficient eligible resources for the creation of the specified virtual disk.

Recommended Actions:
- Choose a combination of FaultDomainAwareness and NumberOfDataCopies (or PhysicalDiskRedundancy) supported by the
storage pool.
- Choose a value for NumberOfColumns that is less than or equal to the number of physical disks in the storage fault
domain selected for the virtual disk.

Activity ID: {8a6e42df-7616-4ac4-85e5-8682dac4f3e0}
At line:1 char:1
+ new-virtualdisk -FriendlyName test -StoragePoolFriendlyName test -siz ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (StorageWMI:ROOT/Microsoft/...SFT_StoragePool) [New-VirtualDisk], CimE
   xception
    + FullyQualifiedErrorId : StorageWMI 1,New-VirtualDisk

PS C:\Users\Administrator> new-virtualdisk -FriendlyName test -StoragePoolFriendlyName test -size 10gb -ProvisioningType fixed -ResiliencySettingName parity

FriendlyName ResiliencySettingName FaultDomainRedundancy OperationalStatus HealthStatus  Size FootprintOnPool StorageEf
                                                                                                               ficiency
------------ --------------------- --------------------- ----------------- ------------  ---- --------------- ---------
test         Parity                1                     OK                Healthy      10 GB           17 GB    58.82%


PS C:\Users\Administrator> get-virtualdisk | ft friendlyname, resiliencysettingname, numberofcolumns

friendlyname resiliencysettingname numberofcolumns
------------ --------------------- ---------------
test         Parity                              3


PS C:\Users\Administrator> new-virtualdisk -FriendlyName test -StoragePoolFriendlyName test -size 10gb -ProvisioningType fixed -ResiliencySettingName parity

FriendlyName ResiliencySettingName FaultDomainRedundancy OperationalStatus HealthStatus  Size FootprintOnPool StorageEf
                                                                                                               ficiency
------------ --------------------- --------------------- ----------------- ------------  ---- --------------- ---------
test         Parity                1                     OK                Healthy      10 GB           17 GB    58.82%


PS C:\Users\Administrator> get-virtualdisk | ft friendlyname, resiliencysettingname, numberofcolumns

friendlyname resiliencysettingname numberofcolumns
------------ --------------------- ---------------
test         Parity                              3


PS C:\Users\Administrator>