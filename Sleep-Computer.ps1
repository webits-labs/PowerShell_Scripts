# Suspend the system
Start-Process -FilePath rundll32.exe -ArgumentList 'powrprof.dll,SetSuspendState' -Verb RunAs


<# Alternative option:
    <#---Resources---
        1. https://mypowershellnotes.wordpress.com/2020/10/21/put-your-computer-to-sleep-from-powershell/
    #>

# Import the required assemblies
Add-Type -AssemblyName System.Windows.Forms

# Suspend the computer
[System.Windows.Forms.SystemInformation]::SetSuspendState(
  [System.Windows.Forms.PowerState]::Suspend,
  $false,
  $false
)

#>
