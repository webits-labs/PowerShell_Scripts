#Websites
	#https://blogs.msdn.microsoft.com/virtual_pc_guy/2010/11/11/configuring-remote-management-of-hyper-v-server-in-a-workgroup/
	#https://msdn.microsoft.com/en-us/virtualization/hyperv_on_windows/user_guide/remote_host_management
	#http://www.tomsitpro.com/articles/how-to-remotely-manage-nano-server,2-1051.html
	#https://social.technet.microsoft.com/Forums/office/en-US/0141f7bd-caa4-4290-a2b4-54ff54b937d6/server-2012-server-manager-winrm-negotiate-authentication-error?forum=winserver8gen

#On Host
	Enable-PSRemoting
	Winrm Quickconfig 
	Enable-WSManCredSSP -Role server
    
	#Verify firewall profiles are enabled
        	Get-NetFirewallProfile
   	
	#Set profiles to disable 
        	Set-NetFirewallProfile –Enabled False
	
	#Verify firewall profiles are disabled
        	Get-NetFirewallProfile
	#Optional, add registry key to Read Only access to Device Manager
		New-ItemProperty -Name LocalAccountTokenFilterPolicy -path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -propertyType DWord -value 1

# On Client
	#Install RSAT for Win 10

	#Add the 192.168.1.30 computer to an existing list of trusted hosts, use the following command:
    		Set-Item wsman:\localhost\Client\TrustedHosts 192.168.1.30 -Concatenate -Force

	# Verify the IP was added to the trusted hosts list, use the following command:
    		get-item wsman:\localhost\client\trustedhosts

	Winrm Quickconfig

	Enable-WSManCredSSP -Role client -DelegateComputer 192.168.1.30


#after joining Host to domain, 

	#remove Client from trusted clients list
   		Clear-Item WSMan:\localhost\Client\TrustedHosts

	#Set firewall profiles to disable 
        	Set-NetFirewallProfile –Enabled




