<#get-childitem -Path "D:\Cache\Movies | where-object {$_.lastwritetime -lt (get-date).adddays(-30)} | move-item -destination "P:\Movies"

#>

#Get list of items in PlexCache Folders
    #Movies example:
        Get-ChildItem -Path "D:\PlexCache\Movies"

# Get list of items in Cache folder older than 31 days (Use for hot/cold Storage)
    #Movies example:
        Get-ChildItem -Path "D:\PlexCache\Movies" | Where-Object {$_.lastwritetime -lt (Get-Date).AddDays(-31)}

#Move items from PlexCache Folders
    #Movie example:
        Get-ChildItem -Path "D:\Cache\Movies" | Move-Item -Destination "P:\Movies"

# Move items from Cache folder older than 31 days (Use for hot/cold Storage)
    #Movie example:
        Get-ChildItem -Path "D:\PlexCache\Movies" | Where-Object {$_.lastwritetime -lt (Get-Date).AddDays(-31)} | Move-Item -Destination "P:\Movies"



    




