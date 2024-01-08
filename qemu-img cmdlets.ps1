#Run qemu-img.exe as .\ from local install folder
	Example: PS C:\QEMU-IMG> .\qemu-img.exe info 'H:\LocalData.vhd' (vhdx, vdi, raw, vmdk)
		<#image: h:\KVM Testing\LocalData.vhd
		file format: vpc
		virtual size: 30G (32212647936 bytes)
		disk size: 8.9G
		cluster_size: 2097152#>

PS C:\Users\Mike\Desktop\QEMU-IMG> .\qemu-img.exe info 'h:\KVM Testing\LocalData.vhdx'
	image: h:\KVM Testing\LocalData.vhdx
	file format: vhdx
	virtual size: 30G (32212647936 bytes)
	disk size: 9.0G
	cluster_size: 33554432

PS C:\Users\Mike\Desktop\QEMU-IMG> .\qemu-img.exe info 'h:\KVM Testing\kvmlocaldata.vhdx'
	image: h:\KVM Testing\kvmlocaldata.vhdx
	file format: vhdx
	virtual size: 30G (32212254720 bytes)
	disk size: 1.2M
	cluster_size: 16777216