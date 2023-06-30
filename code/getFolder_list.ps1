$folders = (get-childitem  -path "f:\n1_2023\f\nebula\archive$"  -Directory)


foreach ($folder in $folders)
{
    $myfolder = $folder.fullname

 
    write-host "robocopy $myfolder"

}
