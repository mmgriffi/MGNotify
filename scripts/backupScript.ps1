
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

$myservers = "CCEPAP475N19.cdcprod.mfg.intel.com",
"CCEPAP475N20.cdcprod.mfg.intel.com",
"CCEPAP475N10.cdcprod.mfg.intel.com",
"CCEPAP475N6.cdcprod.mfg.intel.com",
"CCEPAP475N7.cdcprod.mfg.intel.com",
"CCEPAP475N8.cdcprod.mfg.intel.com",
"CCEPAP475N9.cdcprod.mfg.intel.com",
"CCEPAP475N11.cdcprod.mfg.intel.com",
"CCEPAP475N12.cdcprod.mfg.intel.com",
"CCEPAP475N13.cdcprod.mfg.intel.com",
"CCEPAP475N1.cdcprod.mfg.intel.com",
"CCEPAP475N2.cdcprod.mfg.intel.com",
"CCEPAP475N3.cdcprod.mfg.intel.com",
"CCEPAP475N4.cdcprod.mfg.intel.com",
"CCEPAP475N5.cdcprod.mfg.intel.com",
"CCE4PAP475N1.cdcprod.mfg.intel.com",
"CCE4PAP475N2.cdcprod.mfg.intel.com",
"CCE4PAP475N3.cdcprod.mfg.intel.com",
"CCE4PAP475N4.cdcprod.mfg.intel.com",
"CCE4PRD437N1.cdcprod.mfg.intel.com",
"CCE4PRD437N2.cdcprod.mfg.intel.com",
"CCEPRD437N3.cdcprod.mfg.intel.com",
"CCEPRD437N1.cdcprod.mfg.intel.com",
"CCEPRD437N2.cdcprod.mfg.intel.com",
"CCEPAP475N23.cdcprod.mfg.intel.com",
"CCEPAP475N24.cdcprod.mfg.intel.com",
"CCEPAP475N16.cdcprod.mfg.intel.com",
"CCEPAP475N17.cdcprod.mfg.intel.com"

$myservers = "CCEIAP475N1.cdcprod.mfg.intel.com",
             "CCEIAP475N2.cdcprod.mfg.intel.com",
             "CCEIRD437N1.cdcprod.mfg.intel.com",
             "CCEIRD437N2.cdcprod.mfg.intel.com"

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


$folders = "bin",
"SchedulerAdmin",
"scripts"
$sourceRoot = "D:\Program Files\Intel\PCSA"
$backupFolder = "D:\Program Files\Intel\PCSA\backup\ww17"
$results = @()

foreach ($server in $odd)  #or $even
{
$result = (backupFolders $server $folders $sourceRoot $backupFolder)
$results +=$result
}

$results

