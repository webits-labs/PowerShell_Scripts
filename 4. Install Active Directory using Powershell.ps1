#Websites
    #https://blogs.technet.microsoft.com/uktechnet/2016/06/08/setting-up-active-directory-via-powershell/

#List windows features related to Active Directory
    get-windowsfeature -name AD*

#Locate Active Directory Domain Services Feature

#Installing Active Directory Domain Service
    install-windowsfeature AD-Domain-Services

#Importing Required Modules
    Import-module ADDSDeployment

#Verify ADDS role installed successfully
    Get-WindowsFeature -Name *AD*

#Promote server to Domain Controller
#First Domain Controller in Forest (Do not break lines prior to executing)
    Install-ADDSForest
    -CreateDnsDelegation:$false
    -DatabasePath “C:\Windows\NTDS”
    -DomainMode “Win2012R2”
    -DomainName “ELEMENTAL.LOCAL”
    -DomainNetbiosName “ELEMENTAL”
    -ForestMode “Win2012R2”
    -InstallDns:$true
    -LogPath “C:\Windows\NTDS”
    -NoRebootOnCompletion:$false
    -SysvolPath “C:\Windows\SYSVOL”
    -Force:$true

#Other options include:
    Install-ADDSDomainController (Install additional domain controller in domain)
    Uninstall-ADDSDomainController	(Uninstall the domain controller from server)

#Creating users:
    #http://www.windowsnetworking.com/articles-tutorials/windows-server-2012/creating-active-directory-accounts-using-powershell.html
        $user=Get-ADUser -Identity administrator
        New-ADUser -Instance $user -SamAccountName Temp

    #Set Password for new account
    #https://technet.microsoft.com/en-us/library/ee617261.aspx
        Set-ADAccountPassword -Identity Temp
