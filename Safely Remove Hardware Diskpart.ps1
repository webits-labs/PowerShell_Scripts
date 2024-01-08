diskpart
list volume
select volume <number> (Where number is the number in the list you see when you list the volumes)
remove all dismount
exit


#Clean HDD/Create Primary Partition
#http://www.jwgoerlich.us/blogengine/post/2009/11/05/Use-Diskpart-to-Create-and-Format-Partitions.aspx
    C:\> Diskpart

    DISKPART> list disk
    DISKPART> select disk (id)
    DISKPART> online disk (if the disk is not online)
    DISKPART> attributes disk clear readonly
    DISKPART> clean
    DISKPART> convert mbr (or gpt)
    DISKPART> create partition primary
    DISKPART> select part 1
    DISKPART> active (if this is the boot partition)
    DISKPART> format fs=ntfs label=(name) quick
    DISKPART> assign letter (letter)
    DISKPART> list volume
