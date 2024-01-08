#Get Service
    #Get information about all the services installed on your computer
        Get-Service

    #take the data returned by Get-Service and pipe it through the Where-Object cmdlet.
    #In turn, Where-Object filters out everything except those services that are stopped:
    #Replace "Stopped" with "Running" to filter out services that are running
        Get-Service | Where-Object {$_.status -eq "stopped"}

    #Sort that returned data any way you want. For example, this command sorts services first by Status, and then by DisplayName:
        Get-Service | Sort-Object status,displayname

    #To get Services that contain a specific letter or displayname
        Get-Service -DisplayName *a*

#Restart Services
    #To use Restart-Service simply call the cmdlet followed by the service name:
        Restart-Service btwdins

    #To restart multiple services just specify the name of each service, separated by commas:
        Restart-Service btwdins,alerter

    #Add the -displayname parameter and specify the service display name (the name shown in the Services snap-in) instead:
        Restart-Service -displayname "bluetooth service"

#Start Services
    #To start a service, simply call Start-Service followed by the service name
        Start-Service btwdins

    #you can add the -displayname parameter and start the service using the service display name, the name that appears in the Services snap-in:
        Start-Service -displayname "Bluetooth service"

#Stop Services
    #To stop a service, simply call Stop-Service followed by the service name (that is, the name of the service as stored in the registry):
        Stop-Service btwdins

    #you can add the -displayname parameter and stop the service using the service display name, the name that appears in the Services snap-in:
        Stop-Service -displayname "Bluetooth service"