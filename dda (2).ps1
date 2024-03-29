
  Id CommandLine                                                                                                       
  -- -----------                                                                                                       
   cd .\Desktop\                                                                                                     
   .\DDA.ps1                                                                                                         
   
   Get-VMHost | Format-List IovSupport, IovSupportReasons
                                                                                                     
   Set-VM -GuestControlledCacheTypes $true -VMName ddatest                                                           
   Set-VM -LowMemoryMappedIoSpace 3Gb -VMName ddatest                                                                
   Set-VM -HighMemoryMappedIoSpace 33280Mb -VMName ddatest                                                           
   Dismount-VMHostAssignableDevice -LocationPath "PCIROOT(0)#PCI(0100)#PCI(0000)"                                                                   
                                                                                   
   Add-VMAssignableDevice -LocationPath "PCIROOT(0)#PCI(0100)#PCI(0000)" -VMName ddatest                             
                                                                                   


