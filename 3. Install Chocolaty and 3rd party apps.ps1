# Install boxstarter:
. { iwr -useb http://boxstarter.org/bootstrapper.ps1 } | iex; get-boxstarter -Force

# You might need to set: 
Set-ExecutionPolicy Unrestricted
#or
Set-ExecutionPolicy RemoteSigned

# Run this boxstarter by calling the following from an **elevated** command-prompt:
# 	start http://boxstarter.org/package/nr/url?<URL-TO-RAW-GIST>
# OR
# 	Install-BoxstarterPackage -PackageName <URL-TO-RAW-GIST> -DisableReboots
#
# Learn more: http://boxstarter.org/Learn/WebLauncher

#---- TEMPORARY ---
#Disable-UAC
New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value 0 -Force

#--- Fonts ---
choco install inconsolata -y
  
#--- Windows Settings ---
Disable-BingSearch
Disable-GameBarTips

Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions
Set-TaskbarOptions -Size Small -Dock Bottom -Combine Full -Lock
Set-TaskbarOptions -Size Small -Dock Bottom -Combine Full -AlwaysShowIconsOn

#--- Windows Subsystems/Features ---
choco install Microsoft-Hyper-V-All -source windowsFeatures
choco install Microsoft-Windows-Subsystem-Linux -source windowsfeatures

#--- Tools ---
# choco install git -params '"/GitAndUnixToolsOnPath /WindowsTerminal"' -y
# choco install poshgit
choco install sysinternals -y
# choco install vim

#--- Apps ---
choco install googlechrome -y
choco install docker-for-windows
choco install sharex
# choco install microsoft-teams
# choco install vcxsrv

#--- Restore Temporary Settings ---
Enable-UAC
Enable-MicrosoftUpdate
Install-WindowsUpdate -acceptEula