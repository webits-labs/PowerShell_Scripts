# 
2 # These variables are device properties.  For people who are very 
3 # curious about this, you can download the Windows Driver Kit headers and 
4 # look for pciprop.h.  All of these are contained in that file. 
5 # 
6 $devpkey_PciDevice_DeviceType = "{3AB22E31-8264-4b4e-9AF5-A8D2D8E33E62}  1" 
7 $devpkey_PciDevice_RequiresReservedMemoryRegion = "{3AB22E31-8264-4b4e-9AF5-A8D2D8E33E62}  34" 
8 $devpkey_PciDevice_AcsCompatibleUpHierarchy = "{3AB22E31-8264-4b4e-9AF5-A8D2D8E33E62}  31" 
9 
 
10 $devprop_PciDevice_DeviceType_PciConventional                        =   0 
11 $devprop_PciDevice_DeviceType_PciX                                   =   1 
12 $devprop_PciDevice_DeviceType_PciExpressEndpoint                     =   2 
13 $devprop_PciDevice_DeviceType_PciExpressLegacyEndpoint               =   3 
14 $devprop_PciDevice_DeviceType_PciExpressRootComplexIntegratedEndpoint=   4 
15 $devprop_PciDevice_DeviceType_PciExpressTreatedAsPci                 =   5 
16 $devprop_PciDevice_BridgeType_PciConventional                        =   6 
17 $devprop_PciDevice_BridgeType_PciX                                   =   7 
18 $devprop_PciDevice_BridgeType_PciExpressRootPort                     =   8 
19 $devprop_PciDevice_BridgeType_PciExpressUpstreamSwitchPort           =   9 
20 $devprop_PciDevice_BridgeType_PciExpressDownstreamSwitchPort         =  10 
21 $devprop_PciDevice_BridgeType_PciExpressToPciXBridge                 =  11 
22 $devprop_PciDevice_BridgeType_PciXToExpressBridge                    =  12 
23 $devprop_PciDevice_BridgeType_PciExpressTreatedAsPci                 =  13 
24 $devprop_PciDevice_BridgeType_PciExpressEventCollector               =  14 
25 
 
26 $devprop_PciDevice_AcsCompatibleUpHierarchy_NotSupported             =   0 
27 $devprop_PciDevice_AcsCompatibleUpHierarchy_SingleFunctionSupported  =   1 
28 $devprop_PciDevice_AcsCompatibleUpHierarchy_NoP2PSupported           =   2 
29 $devprop_PciDevice_AcsCompatibleUpHierarchy_Supported                =   3 
30 
 
31 
 
32 write-host "Generating a list of PCI Express endpoint devices" 
33 $pnpdevs = Get-PnpDevice -PresentOnly 
34 $pcidevs = $pnpdevs | Where-Object {$_.InstanceId -like "PCI*"} 
35 
 
36 foreach ($pcidev in $pcidevs) { 
37     Write-Host "" 
38     Write-Host "" 
39     Write-Host -ForegroundColor White -BackgroundColor Black $pcidev.FriendlyName 
40 
 
41     $rmrr =  ($pcidev | Get-PnpDeviceProperty $devpkey_PciDevice_RequiresReservedMemoryRegion).Data 
42     if ($rmrr -ne 0) { 
43         write-host -ForegroundColor Red -BackgroundColor Black "BIOS requires that this device remain attached to BIOS-owned memory.  Not assignable." 
44         continue 
45     } 
46 
 
47     $acsUp =  ($pcidev | Get-PnpDeviceProperty $devpkey_PciDevice_AcsCompatibleUpHierarchy).Data 
48     if ($acsUp -eq $devprop_PciDevice_AcsCompatibleUpHierarchy_NotSupported) { 
49         write-host -ForegroundColor Red -BackgroundColor Black "Traffic from this device may be redirected to other devices in the system.  Not assignable." 
50         continue 
51     } 
52 
 
53     $devtype = ($pcidev | Get-PnpDeviceProperty $devpkey_PciDevice_DeviceType).Data 
54     if ($devtype -eq $devprop_PciDevice_DeviceType_PciExpressEndpoint) { 
55         Write-Host "Express Endpoint -- more secure." 
56     } else { 
57         if ($devtype -eq $devprop_PciDevice_DeviceType_PciExpressRootComplexIntegratedEndpoint) { 
58             Write-Host "Embedded Endpoint -- less secure." 
59         } else { 
60             if ($devtype -eq $devprop_PciDevice_DeviceType_PciExpressTreatedAsPci) { 
61                 Write-Host -ForegroundColor Red -BackgroundColor Black "BIOS kept control of PCI Express for this device.  Not assignable." 
62             } else { 
63                 Write-Host -ForegroundColor Red -BackgroundColor Black "Old-style PCI device, switch port, etc.  Not assignable." 
64             } 
65             continue 
66         } 
67     } 
68 
 
69     $locationpath = ($pcidev | get-pnpdeviceproperty DEVPKEY_Device_LocationPaths).data[0] 
70 
 
71     # 
72     # Now do a check for the interrupts that the device uses.  Line-based interrupts 
73     # aren't assignable. 
74     # 
75     $doubleslashDevId = "*" + $pcidev.PNPDeviceID.Replace("\","\\") + "*" 
76     $irqAssignments = gwmi -query "select * from Win32_PnPAllocatedResource" | Where-Object {$_.__RELPATH -like "*Win32_IRQResource*"} | Where-Object {$_.Dependent -like $doubleslashDevId} 
77 
 
78     #$irqAssignments | Format-Table -Property __RELPATH 
79 
 
80     if ($irqAssignments.length -eq 0) { 
81         Write-Host -ForegroundColor Green -BackgroundColor Black "    And it has no interrupts at all -- assignment can work." 
82     } else { 
83         # 
84         # Find the message-signaled interrupts.  They are reported with a really big number in 
85         # decimal, one which always happens to start with "42949...". 
86         # 
87         $msiAssignments = $irqAssignments | Where-Object {$_.Antecedent -like "*IRQNumber=42949*"} 
88      
89         #$msiAssignments | Format-Table -Property __RELPATH 
90 
 
91         if ($msiAssignments.length -eq 0) { 
92             Write-Host -ForegroundColor Red -BackgroundColor Black "All of the interrupts are line-based, no assignment can work." 
93             continue 
94         } else { 
95             Write-Host -ForegroundColor Green -BackgroundColor Black "    And its interrupts are message-based, assignment can work." 
96         } 
97     } 
98 
 
99     # 
100     # Print out the location path, as that's the way to refer to this device that won't 
101     # change even if you add or remove devices from the machine or change the way that 
102     # the BIOS is configured. 
103     # 
104     $locationpath 
105 } 
106 
 
107 # 
108 # Now look at the host as a whole.  Asking whether the host supports SR-IOV 
109 # is mostly equivalent to asking whether it supports Discrete Device 
110 # Assignment. 
111 # 
112 if ((Get-VMHost).IovSupport -eq $false) { 
113     Write-Host "" 
114     write-host "Unfortunately, this machine doesn't support using them in a VM." 
115     Write-Host "" 
116     (Get-VMHost).IovSupportReasons 
117 }