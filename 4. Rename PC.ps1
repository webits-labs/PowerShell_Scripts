# --- Rename the Computer ---
# ---Requires restart

$computername = "MikesVMTest2"
if ($env:computername -ne $computername) {
	Rename-Computer -NewName $computername #-Restart
}


#Restart-computer
