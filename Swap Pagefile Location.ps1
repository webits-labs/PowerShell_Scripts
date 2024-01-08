$computer = Get-WmiObject Win32_computersystem -EnableAllPrivileges
$computer.AutomaticManagedPagefile = $false
$computer.Put()
$CurrentPageFile = Get-WmiObject -Query "select * from Win32_PageFileSetting where name='c:\\pagefile.sys'"
$CurrentPageFile.delete()
Set-WMIInstance -Class Win32_PageFileSetting -Arguments @{name="t:\pagefile.sys";InitialSize = 1024; MaximumSize = 4068}



#Fing Pagefile Current Location
$PSLocation = Get-WmiObject -Query "select * from Win32_PageFilesetting"
$PSLocation.SettingID
# Or
Invoke-Expression "wmic pagefile list /format:list"
Invoke-Expression "wmic pagefile list | where {$_.Name}"

#Connect to remote server
Enter-PSSession -ComputerName serv-hv01

