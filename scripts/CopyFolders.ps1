<#
#####################################################
.SYNOPSIS

     BackupPCSAFolders backup selected folders on PCSA servers
.DESCRIPTION
.EXAMPLE
        Example of how to run the script.
.NOTES
     Author     : Mike Griffin
     04 May 2023 : initial version
#######################################################
#>

$myservers = ""

$odd = @()
$even = @()

foreach ($myserver in $myServers)
{

    $server,$rest = $myserver -split '\.',2
    $ser,$srvNum = $server.split("N")
    if ($srvNum % 2 -eq 0)
    {
       $even += $myserver
   
    }
    else
    {
        $odd += $myserver
    }
}

$odd = $odd | Sort-object
$even = $even | Sort-object

function backupFolders($server, $folders ,$sourceRoot, $backupFolder)
{
   write-host "$server, $folders, --- $sourceRoot , $backupFolder"
   
    $scriptblock =
    {
            param ($folders,
            $sourceroot,
            $backupFolder)

            write-host "$folders" -ForegroundColor green
            write-host "$sourceroot" -ForegroundColor Yellow
            write-host "$backupFolder" -ForegroundColor Gray

            $folders.Where({ $_ -ne " " })

            $CURDIR = $PSScriptRoot
            $logdate = (get-date).ToString("dd-MMM-yyyy")
            $myScript = [IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
            $my_log = "$myscript" + "_" + $logdate + ".log"


            $folders = $folders.Split(' ')
            $hostname = hostname
#            $sourceRoot = "D:\Program Files\Intel\PCSA"
#            $backupFolder = "D:\temp\PCSA_backup"
            $errorcode = 0;
            if (!( test-path $backupFolder))
            {
                new-item $backupFolder -itemtype directory
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
                    new-item $destination -itemtype directory
                    "creating  $destination" | out-file "$CURDIR\$my_log" -append
                }
                try
                {
                    Copy-Item -Path $source\* -Destination $destination -recurse -force -ErrorAction SilentlyContinue
                    "creating  $destination" | out-file "$CURDIR\$my_log" -append
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
    $params1 = @{ 'ComputerName'=$server;
               'Scriptblock'=$scriptblock
               'ArgumentList'="$folders $sourceRoot $backupFolder"}

        $params = @{ 'Scriptblock'=$scriptblock
               'ArgumentList'="$folders, $sourceRoot, $backupFolder"}


   #write-host "'ComputerName'=$server; 'Scriptblock'=scriptblock 'ArgumentList'='$folders,$sourceRoot,$backupFolder '"
  #$copyResult = (invoke-command @params)

   invoke-command -ScriptBlock $scriptblock -ArgumentList "$folders", "$sourceRoot", "$backupFolder"


   #$computer = "localhost"
   #Invoke-Command -ComputerName $Computer -ScriptBlock {param($comp) write-host "This script is running on machine: $Comp" } -ArgumentList $Computer

 return "$copyResult"
       
}

$folders = "bin",
"SchedulerAdmin",
"scripts"

$sourceRoot = "D:\Program Files\Intel\PCSA"
$backupFolder = "D:\Program Files\Intel\PCSA\backup\ww17"

$folders = "gittest"
$sourceRoot = "c:\temp"
$backupFolder = "c:\temp\dest"



$results = @()

foreach ($server in $odd)  #or $even
{
#write-host "$server" -ForegroundColor yellow
#$server = "cceiap475n2.cdcprod.mfg.intel.com"
$result = (backupFolders $server $folders $sourceRoot $backupFolder)

$results +=$result
}

$results

backupFolders "locahost" $folders $sourceRoot $backupFolder
