[CmdletBinding()]
param
(
[Parameter(Mandatory= $true,ValueFromPipeline=$true)]
[String]$server,
[Parameter(Mandatory= $true,ValueFromPipeline=$true)]
[String[]]
$folders,
[Parameter(Mandatory= $true,ValueFromPipeline=$true)]
[String]$source,
[Parameter(Mandatory= $true,ValueFromPipeline=$true)]
[string]$backupFolder
)



function backupFolders($server, $folders ,$sourceRoot, $backupFolder)
{
   write-host "$server, $folders, --- $sourceRoot , $backupFolder"
    foreach ($folder in $folders)
    {
        write-host "$folder" -ForegroundColor yellow
    }

    $scriptblock =
    {
            param ($folders,
            $sourceroot,
            $backupFolder)

            write-host "$folders" -ForegroundColor green
            write-host "$sourceroot" -ForegroundColor Yellow
            write-host "$backupFolder" -ForegroundColor Gray

            $folders.Split(',')
            $folders.Where({ $_ -ne " " })
            $CURDIR = $PSScriptRoot
            write-host "$CURDIR"
            $logdate = (get-date).ToString("dd-MMM-yyyy")
            $myScript = [IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
            $my_log = "$myscript" + "_" + $logdate + ".log"
            $folders = $folders.Split(' ')
            $hostname = hostname
            $errorcode = 0;
            if (!( test-path $backupFolder))
            {
                try
                {
                new-item -path $backupFolder -itemtype directory -force
                }
                catch
                {
                write-host "$_.exception"
                }

            }
            if (!(test-path "$CURDIR\$my_log"))
            {
                "new file" | out-file "$CURDIR\$my_log"
            }
        $copyresults = @()
        foreach ($folder in $folders)
            {
               if ($folder -ne "")
               {
                "attempting copy of $sourceRoot $folder to $backupFolder" | out-file "$CURDIR\$my_log" -append
                $source = join-path $sourceRoot $folder
                $destination = join-path $backupFolder $folder  #create the destination folder if it does not exist. This avoids a error "Container cannot be copied onto existing leaf item"
                if (!( test-path $destination))
                {
                    new-item $destination -itemtype directory -force
                    "creating  $destination" | out-file "$CURDIR\$my_log" -append
                }
                try
                {
                    Copy-Item -Path $source\* -Destination $destination -recurse -force -ErrorAction SilentlyContinue
#                    "creating  $destination" | out-file "$CURDIR\$my_log" -append
                    $copyresults += "$hostname,$folder,0"
                }
                catch
                {
                  write-host "$_.exception" -ForegroundColor red  
                  $copyresults += "$hostname,$folder,999"
                  #$errorcode = 999    
                 }
              }
            }
    #return $errorcode
    return $copyresults
    }
   invoke-command -ComputerName $server -ScriptBlock $scriptblock -ArgumentList "$folders", "$sourceRoot", "$backupFolder"
   return "$copyResult"
}

backupFolders -server $server -folders $folders -spource $sourceRoot -backupFolder $backupFolder
