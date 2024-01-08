Set-ExecutionPolicy Unrestricted

# CD to VHD or VHDX file

# Verify the VHD
get-vhd 'f:\Local OneDrive Sync.vhd'

# Convert VHD to VHDX
*Use this:
convert-vhd -Path 'H:\LocalData.vhd' -DestinationPath 'H:\LocalData.vhdx'


# Copy to Archives
convert-vhd -Path 'H:\Backups\Windows 10.vhdx' -DestinationPath 'H:\Archives\ARCHIVE - Windows 10 DATE.vhdx'

# If failure to mount, verify Sparse flag state:
  fsutil sparse queryflag

  <#Example
    PS h:\> fsutil sparse queryflag .\LocalData.vhd
    This file is set as sparse#>

# If Sparse flag IS set to Sparse:
change Flag state by copying VHD to new location 

#After copying, re-run check on new file to verify it is NOT sparse:
  fsutil sparse queryflag
 
  <#Example:
   PS h:\KVM Testing> fsutil sparse queryflag .\LocalData.vhd
   This file is NOT set as sparse#>


##Testing Do Not Use
convert-vhd -Path 'H:\Backups\Local OneDrive Sync.vhd' -DestinationPath 'H:\Archives\ARCHIVE - Local OneDrive Sync 2018.10.14.vhdx'

