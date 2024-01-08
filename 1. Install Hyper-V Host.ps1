#Websites:
    #http://www.tomsitpro.com/articles/hyper-v-powershell-cmdlets,2-779.html
    #https://technet.microsoft.com/en-us/windows-server-docs/compute/hyper-v/get-started/install-the-hyper-v-role-on-windows-server


# Install Hyper-V role.  If you're connected locally to the server, run the command without -ComputerName <computer_name>.
    Install-WindowsFeature -Name Hyper-V -ComputerName <computer_name> -IncludeManagementTools -Restart

#Verify Hyper-V role installed successfully
    Get-WindowsFeature -Name *Hyper*

#To enable Hyper-V on Windows 10, use the following script:
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

