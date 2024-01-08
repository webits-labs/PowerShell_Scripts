Function - Enable Game Mode on external display
Purpose: Switch Windows desktop into "Deck Mode" for external monitor gaming

# ---Step 1: turn off steam deck display.
     # Purpose: reduce resource utilization by disabling the built in deck display for exclusive 1080P desktop gaming
    $monitors = Get-WmiObject -Class "Win32_DesktopMonitor"
	$monitor1 = $monitors | Select-Object -First 1
	$monitor1.SetPowerState(3)
# To turn off the second or third monitor, modify line 2 above with: 
	# $monitor2 = $monitors | Select-Object -Index 1
	# $monitor3 = $monitors | Select-Object -Last 1

#---Step 2: Disable all un-necessary processes and services 
    # Purpose: Reduce resource utilization by freeing up CPU, RAM, NET and GPU resources for games

#Option 1:
# Get-Process | Where-Object {$_.Name -like "AMD*"} | Stop-Process
# Get-Service | Where-Object {$_.Name -like "AMD*"} | Stop-Service

#Option 2:
	$processes = Get-Process
	$services = Get-Service | Where-Object {$_.Status -eq "Running"}

	Write-Output "Processes:"
	$processes | Format-Table -Property ID, Name, Path 

	Write-Output "Services:"
	$services | Format-Table -Property Name, DisplayName, Status

	$stopProcess = Read-Host "Enter the name of a process to stop (leave blank to skip):"
	$stopService = Read-Host "Enter the name of a service to stop (leave blank to skip):"

	if ($stopProcess -ne "")
	{
		Stop-Process -Name $stopProcess -Force
	}

	if ($stopService -ne "")
	{
		Stop-Service -Name $stopService
	}

# Disable the steam deck display on a triple monitor setup and set the second monitor as the primaryMonitor
# Disable the 1st monitor 	
	$monitors = Get-WmiObject -Class "Win32_DesktopMonitor"
	$firstMonitor = $monitors | Select-Object -First 1
	$firstMonitor.SetPowerState(3)
# Set the second monitor as the primary Monitor
	$secondMonitor = $monitors | Select-Object -Index 1
	$secondMonitor.IsPrimary = $true
# Set the third monitor as the primary Monitor
	# $thirdMonitor = $monitors | Select-Object -Last 1
	# $secondMonitor.IsPrimary = $true

