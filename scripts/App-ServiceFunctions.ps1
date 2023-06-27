<#
.SYNOPSIS
    This set of functions controls services on a server

.DESCRIPTION
    Carries out actions on services based on inputs. Stop / Start / Set startu Mode are supported

.EXAMPLE

 GenericServiceStopStart.ps1 -ComputerName cceiap475n1.cdcprod.mfg.intel.com -action validate  -services "WebSTATISTICA,Schedule"
 WebSTATISTICA,Running,OK
 Schedule,Running,OK


.NOTES

#>
[CmdletBinding()]
param
(
    [Parameter(Mandatory= $true,ValueFromPipeline = $true)]
    [String]$ComputerName,
    [Parameter(Mandatory= $true,ValueFromPipeline = $true)]
    [String]$action,
    [Parameter(Mandatory= $true,ValueFromPipeline = $true)]
    [String[]]
    $services,
    [Parameter(Mandatory= $false,ValueFromPipeline = $true)]
    [String]$timeout,
    [Parameter(Mandatory= $false,ValueFromPipeline = $true)]
    [String]$startupMode
)
$exitcode =999
$myDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$myScript = [IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
$global:now = (get-date).ToString("dd-MMM-yyy HH:MM:ss")
$logdate = (get-date).ToString("dd-MMM-yyyy")
$CURDIR = $PSScriptRoot
$my_log = "$computername" + "_" + "$my_Script" + "_" + $logdate + ".log"

$services = $services.split(",")


#$logdir = join-path $CURDIR logs
$logDir = $CURDIR
cd $logDir

#setup a log file with date stamp
if (test-path $logdir\$my_log)
{
       "****** Running $action function on $compuername ***** " | out-file -Filepath $logdir\$my_log -Append

}
else
{
     "****** Running $action function on $compuername ***** " | out-file -Filepath $logdir\$my_log
}
function logstr($logmessage)
{
    "`n[$(get-date -format "yyyy-MM-dd HH:mm:ss")] : $($logMessage -join " ")" | out-file  -FilePath $logdir\$my_log  -append
}

function stopProcess($serviceName)
{
    write-host "stopProcess :Checking if we need to stop process $serviceName" -ForegroundColor yellow
    $srv_service = get-service -computer $ComputerName -name $serviceName
    $srv_status = $srv_service.Status
    if ($srv_status -eq 'Stopped')
    {
        $srv_flag = $false
        $logMessage = "Service $serviceName is $srv_status . No need to kill the PID"
        logstr $logMessage
        $exitcode = 1
        return $exitcode
    }
    else
    {
        $logMessage = "Service $serviceName is $srv_status. Need to kill the PID"
        write-host "$logMessage"
        logstr "$logMessage"
        start-sleep 2 # wait 2 seconds. It might be winding down.
        $srv_flag = $true
        $process = Get-WmiObject -computer $ComputerName -Class Win32_Service -filter  "name='$($ServiceName)'"
        $name = $process.Name
        $myPID = $process.ProcessID
        write-host "proces ID for $serviceName is $myPID"
            if ($myPID -ne 0)
            {
                try
                {
                    invoke-command -ComputerName $ComputerName -ScriptBlock {Stop-Process  -id $args[0] -force -ErrorAction stop} -ArgumentList $myPID
                    $logMessage = "$name (processis $myPID) stopped"
                    write-host $logMessage -ForegroundColor Green
                    logstr $logMessage
                    $exitcode = 0
                }
                catch
                {
                    $logMessage = "Error : stop-process for $serviceName did not work. $_.exception.description"
                    write-host "$logMessage" -ForegroundColor Red
                    logstr $logMessage
                    $exitcode =1

                }
            }
            else
            {
                write-host "Process ($myPID) was zero. Indicates the service was no longer running when checked. " -ForegroundColor green
            }
    }
    $process = Get-WmiObject -computer $Computername -class Win32_Service -Filter "name='$($serviceName)'"
    $name = $process.name
    $myPID = $process.ProcessID
    write-host "exiting function - PID for $serviceName is $myPID"

    if ($myPID -eq 0)
    {
        $exitcode = 0
    }
    else
    {
        $exitcode = 1
    }
return $exitcode
}

function get-status($serviceName)
{
    $process = Get-WmiObject -computer $Computername -class Win32_Service -Filter "name='$($serviceName)'"
    $srvName = $process.name
    $srvState = $process.State
    $srvStatus = $process.Status
   
   
    if ($srvName.Length -gt 0) {
    $logMessage = "$srvname,$srvState,$srvStatus"
    write-host "$logMessage"
    logstr $logMessage
    }
    else
    {
    $logMessage = "$serviceName,NO_SERVICE,NOT PRESENT"
    write-host "$logMessage"
    logstr $logMessage
    }
   

}

function stop-RemoteService
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'The name of the target system.')]
        [ValidateNotNullOrEmpty()]
        [Alias('CN','MachineName','SystemName')]
        [string[]]$computername,
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = 'The name of the service. Not the display name! ')]
        [ValidateNotNullOrEmpty()]
        [Alias('Name','Service')]
        [string[]]$serviceName,
        [Parameter(Position = 2, HelpMessage = 'The amount of time (in seconds) before reporting a timeout')]
        [int]$timeout
    )
    $timespan = New-Object -TypeName System.TimeSpan -ArgumentList 0,0,$timeout    #mg I removed an additional 0 from this.
    $exitcode = 0
    try
    {
        $ErrorActionPreference = 'stop'
        $svc = get-service -computername $computername -name $serviceName
        #$svc  # DON'T print that !!.. it got back into the return.
        foreach ($sv in $svc)
        {
            $compName = $sv.MachineName

            #write-host "ComputerName : $Computername compname : $compname"
            if ($PSCmdlet.ShouldProcess("$Computername", "Stop $($sv.displayName) service"))
            {
            try
                {
                    $message = "Attempting to stop $($sv.DisplayName) on $Computername .."
                    write-host -ForegroundColor yellow $message -NoNewline
                    logstr $message
                    $status_now = $sv.status
                    write-host $status_now -ForegroundColor green
                    if ($sv.status -ne "Stopped")
                    {
                        $sv.stop()
                       

                    }
                    $sv.WaitforStatus([ServiceProcess.ServiceControllerStatus]::Stopped, $timespan)
                    $message = "[$($sv.MachineName)]: '$($sv.DisplayName) ($($sv.Name))' service is now stopped"
                    logstr $message
                    write-host "$message" -ForegroundColor green
                    $exitcode = 0
                }
            catch [ServiceProcess.TimeoutException]
                {
                    $svc = get-service -computername $computername -name $servicename
                    $logMessage = "Warning: Timed out. Service is in $sv.status  so will proceed to  kill the PID"
                    write-host $logMesage
                    logstr $logMesage
                    stopProcess $serviceName  # call function  to kill the PID., if it is still sctive.
                }
            catch
                {
                    $logMessage = "Error: unable to stop  $_.Exception"
                    logstr $logMessage
                    write-host "$logMessage" -ForegroundColor red
                    $exitcode = 1
                }
            }
        }
    }
    catch
    {
        $message = "Error: $_.Exception.Message"
        logstr $message
        $exitcode = $_.exception.HResult
    }
   return $exitcode
}

function start-RemoteService
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true,Position =0,HelpMessage = 'The name of the target system.')]
        [ValidateNotNullOrEmpty()]
        [Alias('CN','MachineName','SystemName')]
        [string[]]$computername,
        [Parameter(Mandatory = $true,
        position = 1,
        HelpMessage = 'The name of the service. Not the display name! ')]
        [ValidateNotNullOrEmpty()]
        [Alias('Name','Service')]
        [string[]]$serviceName,
        [Parameter(Position = 2,
        HelpMessage = 'The amount of time (in seconds) before reporting a timeout')]
        [int]$timeout 
    )
    $timespan = New-Object -typename System.Timespan -ArgumentList 0,0,0,$timeout
    $exitcode = 0
    $outColor = "Green"
    try
    {
        $ErrorActionPreference = 'stop'
        $svc = get-service -computername $computername -name $serviceName
        foreach ($sv in $svc)
        {
            $compName = $sv.MachineName
            if ($PSCmdlet.ShouldProcess("$Computername", "Start $($sv.displayName) service"))
            {
            try
                {
                    $message = "Attempting to start $($sv.DisplayName) on $Computername .."
                    write-host -ForegroundColor yellow $message -NoNewline
                    logstr $message
                    #$status_now = $sv.status
                    if ($sv.status -ne "Running")
                    {
                        $sv.start()

                    }
                    $sv.WaitforStatus([ServiceProcess.ServiceControllerStatus]::Running, $timespan)
                    $message = "[$($sv.MachineName)]: '$($sv.DisplayName) ($($sv.Name))' service is now running"
                    logstr $message
                    write-host "$message" -ForegroundColor green
                    $exitcode = 0
                }
            catch [ServiceProcess.TimeoutException]
                {
                    $svc = get-service -computername $computername -name $servicename
                    $logMessage += "Warning: Timed out. Service is in $sv.status "
                    write-host $logMesage
                    logstr $logMesage
                    $exitcode = 1
                    $outColor = "Red"
                }
            catch
                {
                    $logMessage += "Error: unable to start $_.Exception.Message"
                    logstr $logMessage
                    write-host "$logMessage" -ForegroundColor red
                    $exitcode = 1
                    $outColor = "Red"

                }

            }
        }
    }
    catch
    {
        $outColor = "Red"
        $message = "Error: $_.Exception.Message"
        logstr $message
        write-host "$message" -ForegroundColor $outcolor
        $exitcode = $_.exception.HResult
    }
   return $exitcode

}

function setServiceStartup
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true,HelpMessage = 'The name of the target system.')]
        [ValidateNotNullOrEmpty()]
        [Alias('CN','MachineName','SystemName')]
        [string[]]$computername,
        
        [Parameter(Mandatory = $true,
        HelpMessage = 'The name of the service. Not the display name! ')]
        [ValidateNotNullOrEmpty()]
        [Alias('Name','Service')]
        [string[]]$servicename,
        
        [Parameter(Mandatory= $true,
        HelpMessage = 'Set to one of the following (Automatic,  Manual  or Disabled)')]
        [ValidateSet('Automatic','Manual','Disabled',IgnoreCase = $true)]
        [Alias('StartMode')]
        [string]$StartType,
        
        [Parameter(Mandatory = $false,
        HelpMessage = 'The name of the log file to save output')]
        [string]$logFile
    )
       
    write-host "$computername, $serviceName,$starttype"
    $exitcode = 0

    $ErrorActionPreference = 'stop'
    $sv = get-wmiobject -computername $computername -class Win32_service |  where { $_.name -eq $serviceName }
    $compName = $sv.SystemName
    write-host "`n$compName"
            if ($PSCmdlet.ShouldProcess("$($sv.systemname)", "Change Type  of $($sv.Displayname) service"))
            {
            try
                {
                    $ErrorActionPreference = 'stop'
                    $result= $($sv.ChangeStartMode("$StartType")).returnValue
                    if ($result -eq 0)
                    {
                        $sv = get-wmiobject -computername $compName -class Win32_service |  where { $_.name -eq $sv.Name }
                        $logmessage = "[$($sv.SystemName)]: Start type of '$($sv.DisplayName) ($($sv.Name))' service is now $($sv.StartMode)"
                        logstr $logMessage
                        write-host "$logMessage"
                    }
                    else
                    {
                     $logmessage = "[$($sv.MachineName)]: Start type of '$($sv.DisplayName) ("+$($sv.Name)+")' service failed to update"
                     logstr $logMessage
                     write-host "$logMessage"

                    $exitCode= $result

                    }
                }
                catch
                {
                    $logMessage = "$_.Exception.Hresult"
                    write-host $logMessage
                    logstr $logMessage
                    $exitCode = $_.Exception.Hresult
                   
                }
        }
  return $exitcode
}

function validateServices
{
    logstr "Checking Service Status"
    foreach ($serviceName in $services)
    {
        get-status $serviceName
    }

}
# LOGIC
if ($action -eq "stopService")
{
    $myExitcode = 0
    $state = "Stopped"
    $message = "Stopping the following services $services"
    $timeout = 2
    logstr $message
    foreach ($serviceName in $services)
        {
            $exitcode = (stop-RemoteService $computername "$serviceName" $timeout)
           # write-host "exit is $exitcode"
             start-sleep 1
             
             write-host "$exitcode $exitcode.gettype()"

             #$myService,$exitcode = $exitcode.split(" ")

            $myExitcode += $exitcode
        }
        if ($myExitcode -eq 0)
        {
            $message = "SUCCESS : All services $state"
            logstr $message
        }
        else
        {
            $message = "ERROR : check logs for errors"
            logstr $message
        }
        validateServices
}
elseif ($action -eq "StartService")
{
    $myExitcode = 0
    $state = "Started"
    $message = "Starting the following services $services"
    logstr $message
    write-host "$message"
    foreach ($serviceName in $services)
        {
            $exitcode = (start-RemoteService $computername "$serviceName")
            write-host "exit is $exitcode"
            start-sleep 2
           $myExitcode += $exitcode
        }

        if ($myExitcode -eq 0)
        {
            $message = "SUCCESS : Finished starting services"
            logstr $message
                write-host "$message"
        }
        else
        {
            $message = "ERROR : check logs for errors"
            logstr $message
                write-host "$message"
        }
        validateServices
   
}
elseif ($action -eq "setServiceStartup")
{
    $myExitcode = 0
    foreach ($serviceName in $services)
    {
        $exitcode = (setServiceStartup $computername "$serviceName" $startupMode)
        $myExitcode += $exitcode
        start-sleep 1
    }
    $logMessage = "finsihed setting startup mode on services"
    logstr $logMessage
    if ($myExitcode -eq 0)
    {
        $message = "SUCCESS : All services set to $startupMode"
        logstr $message
    }
    else
    {
        $message = "ERROR : check logs for error messages"
        logstr $message
    }

}
else
{
    write-host "$action"
    validateServices

}
