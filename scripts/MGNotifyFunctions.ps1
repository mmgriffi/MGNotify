#Functions for EDX notify

#addshare "myLogs" "d:\temp" "amr\pcsa" "cceiap475n1.cdcprod.mfg.intel.com"
#removeShare "mylogs" "cceiap475n1.cdcprod.mfg.intel.com"
#$shareInfo = (invoke-command -computername cceiap475n1.cdcprod.mfg.intel.com -scriptblock {param($share); get-smbshare -name $share} -argumentlist "$myshare")



function installService($service,$workdir,$computername)
{
$scriptblock =
    {

    param(
    [Parameter(Mandatory = $true)][String]$service,
    [Parameter(Mandatory = $true)][String]$workdir
    )

    $ns = $workdir+"\nssm.exe"
    $srvname = "edxnotify_"+$service
    $srvloc = $workdir+"\"+$service+".py"
    $cfgloc = $workdir+"\config.ini"

    $serv_exists = (Get-Service $srvname -ea 0).Length

    if ($serv_exists -ne 0) {
    .$ns remove $srvname confirm -ea 0
        }

    .$ns install $srvname "python" $srvloc $cfgloc
    .$ns set $srvname DisplayName EDXNotify_$service
    .$ns set $srvname Description "EDX Notify "$service
    .$ns set $srvname AppDirectory $workdir
    .$ns set $srvname Start SERVICE_AUTO_START
    }

    invoke-command -ComputerName $computerName -ScriptBlock $scriptblock -ArgumentList "$service","$workdir"
   
}





function addShare($shareName,$path,$userlist,$computerName)
{
   $scriptblock =
        {
         param ($share,
         $path,
         $userlist
         )
        if(!(Get-SMBShare -Name $share -ea 0))
        {
            try
            {
            New-SmbShare -Name $share -Path $path -ReadAccess $userlist   #need a better way to assign security
            return "success : share $share added"
            }
            catch
            {
                return "failure : Cannot add $share"
            }
         }
         else
         {
         return "warning : $share share already exists"
         }
        }
        invoke-command -ComputerName $computerName -ScriptBlock $scriptblock -ArgumentList "$shareName","$path","$userlist"
       
}

function getShareInfo($shareName,$computerName)
{
   $scriptblock =
        {
         param ($share)
        if(Get-SMBShare -Name $share -ea 0) { $shareinfo = (get-smbshare -name $shareName)
        return $shareInfo
         }
         else
         {
            return "$share not found"
         }
        }
        invoke-command -ComputerName $computerName -ScriptBlock $scriptblock -ArgumentList "$shareName"
        return "$copyResult"
}

function removeShare($shareName,$computerName)
{
   $scriptblock =
        {
         param ($share)
        if(Get-SMBShare -Name $share -ea 0)
        {
           try
             {
             Remove-SMBShare -Name $share -Force -ErrorAction SilentlyContinue
             return "success : share $share removed"
             }
             catch
             {
                return "failure : Cannot remove $share"
             }
         }
        else
         {
            return "warning : $share not found"
         }
        }
        invoke-command -ComputerName $computerName -ScriptBlock $scriptblock -ArgumentList "$shareName"
}

function copyInstallFiles($source,$destination,$computername,$replace)
{


$sourceObj = split-path $source -leaf
$destFolder = split-path $destination -leaf
$driveLetter = $destination[0]
$uncdest = "\\${computername}\${driveLetter}$\${destfolder}"


if (test-path $uncdest)
    {
       
        if ((Get-Item $source) -is [System.IO.DirectoryInfo])
        {
        #it is a directory
        if ($replace -eq "yes")
        {
            remove-item -path $uncdest -Recurse -Force
            copy-item -path $source -Recurse -Destination $uncdest -force
        }
        else
        {
            copy-item -path $source -Recurse -Destination $uncdest -force
        }
       
        }
        else
        {
        #it's a single file or archive.
        copy-item -path $source -Destination $uncdest -Force
        }
        if ( test-path $uncdest\$sourceObj )
        {
            return "success $sourceObj copied"
        }
        else
        {
        return "fail $sourceObj not copied"
        }
    }
    else
    {
    return "Path does not exist"
    }
}


#$destination = "D:\temp"

#copyInstallFiles "d:\temp\F24_CMS.xlsx" "d:\temp\" "cceiap475n1.cdcprod.mfg.intel.com"


#$currentDirectory = Get-Location
#$currentDrive = Split-Path -qualifier $currentDirectory.Path
# Mapping a non-network drive? Check the DriveType enum documentation https://docs.microsoft.com/en-us/dotnet/api/system.io.drivetype?view=net-6.0
#$logicalDisk = Get-CimInstance -ClassName Win32_LogicalDisk -filter "DriveType = 4 AND DeviceID = '$currentDrive'"
#$uncPath = $currentDirectory.Path.Replace($currentDrive, $logicalDisk.ProviderName)