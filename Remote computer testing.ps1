$computers = Get-Content -Path C:\Users\mfbuser\Desktop\Powershell\Computers.txt
Get-WmiObject -Class win32_bios -cn $computers -EA silentlyContinue |
Format-table __Server, Manufacturer, Version –AutoSize

-cn 


#Install .net 3.5 to remote servers
#https://blogs.msdn.microsoft.com/sqlblog/2010/01/08/how-to-installenable-net-3-5-sp1-on-windows-server-2008-r2-for-sql-server-2008-and-sql-server-2008-r2/
Import-Module ServerManager
$computers = Get-Content -Path C:\Users\mfbuser\Desktop\Powershell\Computers.txt
Add-WindowsFeature as-net-framework -cn $computers -EA silentlyContinue |


$computers = Get-Content -Path C:\Users\mfbuser\Desktop\Powershell\Computers.txt
set-netfirewallprofile -profile domain,public,private -Enabled False -computername $computers

#set-netfirewallprofile -profile domain,public,private -Enabled True


$computers = Get-Content -Path C:\Users\mfbuser\Desktop\Powershell\Computers.txt 
$computers 

set-netfirewallprofile -profile domain,public,private -Enabled False
