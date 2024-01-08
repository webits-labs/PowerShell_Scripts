#Websites
    #https://technet.microsoft.com/en-us/library/jj205469(v=wps.630).aspx

#List of all available features
    Get-WindowsFeature

#list of features that is installed on a local server
    Get-WindowsFeature | Where Installed

#list of features that is installed on a specified server
    Get-WindowsFeature –ComputerName Server01 | Where Installed

#Return a list of available and installed features that have a command ID starting with AD or Web
    Get-WindowsFeature -Name AD*, Web*