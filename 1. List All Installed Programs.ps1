# Allow scripts to run 
Set-ExecutionPolicy Unrestricted
#or
Set-ExecutionPolicy RemoteSigned

#--- List all installed programs --#
Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall* | sort -property DisplayName | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |Format-Table -AutoSize

#--- List all store-installed programs --#
Get-AppxPackage | sort -property Name | Select-Object Name, Version | Export-Csv -Path c:\test.csv


#Original Script
#--- List all installed programs --#
    #Get-ItemProperty
    #HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*
    #| Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
    #|Format-Table -AutoSize

    #--- List all store-installed programs --#
    #Get-AppxPackage | Select-Object Name, PackageFullName, Version |Format-Table
    #-AutoSize