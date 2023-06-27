<#
#####################################################
.SYNOPSIS

     install Python on PCSA servers
.DESCRIPTION
.EXAMPLE
        Example of how to run the script.
.NOTES
     Author     : Mike Griffin
     27 Jan 2023 : initial version
#######################################################
#>

#$myservers = "CCEPAP475N18.cdcprod.mfg.intel.com"



function createCMD  #write a pip install batch. This is copied to the target server
{

    $pyModule_script = join-path $sourcedir "update_Python.cmd"

    new-item $pyModule_script -type file -force

    "@echo off"  | out-file $pyModule_script -append
    "set LOGFILE=d:\temp\Python_add_modules.log" | out-file $pyModule_script -append
    "call :LOG > %LOGFILE%" | out-file $pyModule_script -append
    "exit /B"   | out-file $pyModule_script -append
    ":LOG"     | out-file $pyModule_script -append
    "Set http_proxy=http://proxy-chain.intel.com:911" | out-file $pyModule_script -append
    "Set https_proxy=http://proxy-chain.intel.com:912" | out-file $pyModule_script -append
    "Cd /d '${installDir}\scripts'" | out-file $pyModule_script -append

    foreach ($module in $pyModules)
    {
    "Pip3.exe install $module --disable-pip-version-check" | out-file $pyModule_script -append
    }
    "exit" | out-file $pyModule_script -append


(Get-Content -path $pyModule_script ) | Set-Content -Encoding ASCII -Path $pyModule_script  -force


}

function copyPython($server) # copy the files2copy to the target server
{
    if (test-path \\$server\d$\temp\)
    {

        foreach ($file in $files2Copy)
        {
            $source = join-path $sourcedir $file
            try
            {
              copy-item $source \\$server\d$\temp\ -ErrorAction SilentlyContinue
              $message = "INFO : $server : $source copied"
                logstr $message
                write-host "$message" -ForegroundColor green

            }
            catch
            {
                $message = "ERROR: $server $_.exception"
                logstr $message
                write-host "$message" -ForegroundColor red

                $serverresult = 999
            }

        }
    }
    else
    {
        $message =  "ERROR: $server : cannot map to server"
        logstr $message
        write-host "$message" -ForegroundColor red
        $serverresult = 999
   
    }
}

Function install_python($server,$installDIR)
{
if ((test_python $server $myversion) -eq $false)
    {
        invoke-command -computername $server -scriptblock { $mydir = $args[0];cd d:\temp;  cmd /c start /wait “%CD%\python-3.7.2-amd64.exe" /quiet InstallAllUsers=1 PrependPath=1 TargetDir=$mydir /log "d:\temp\python_install.log" } -argumentlist $installDIR
        sleep 40
        $message = "INFO : Python $myversion installation executed"
        logstr $message

        if (test_python $server $myversion)
        {  
                $message = "INFO: $server : Python $myversion installed, adding $str_pymodules modules"
                logstr $message
                write-host "$message" -ForegroundColor green
                invoke-command -computername $server -scriptblock { Cmd /c start /wait d:\temp\update_Python.cmd}
                # invoke-command -computername $server -scriptblock { Cmd /c start /wait d:\temp\simplebat.cmd}

                $installed = (invoke-command -computername $server -scriptblock { pip freeze;})
                $message =  "the following modules are installed $installed"

                logstr $message
                write-host "$message" -ForegroundColor green
               
                foreach ($module in $pymodules)
                {
                    if (($installed | select-string $module).count -eq "1")
                    {
                        $message = "INFO : $server; $module was detected"
                        logstr $message
                        write-host $message
                    }
                    else
                    {
                       $message = "INFO : $server; $module was NOT detected"
                       logstr $message
                       write-host $message
                    }
                }
       
        }
        else
        {
                   $message = "ERROR : $server ; Python  not installed - skipping module setup"
                   logstr $message
                   write-host "$message" -ForegroundColor red
                   $serverresult = 999
        }

       
    }
    else
    {
                $message = "INFO : $server ; Python $version already installed - skipping"
                logstr $message
                write-host $message -ForegroundColor yellow
    }
}

function test_python($server,$version)
{
            try
            {
                $Python_version = (invoke-command -computername $server -scriptblock { $python_version = (python --version); return $python_version} -erroraction Ignore)  
                $Progname,$Py_version = $Python_version.split(" ")

                if ($Py_version -eq $version)
                        {
                        write-host "Python $py_version is installed"
                        return $true
                        }
                        elseif ($progname -eq "Python")
                        {
                        write-host "Python $py_version installed, but not $version"
                        return $false
                        }
                        else
                        {
                        write-host "Python is not present"
                        return $false
                        }
            }
            catch
            {
                write-host "$_.exception Python command did not work"
                return $false
            }
        }

function uninstallPython($server,$version)
{
if (test_python $server $version)
    {
        $message =  "INFO : $server : Python $version will be uninstalled"
        write-host "$message" -ForegroundColor yellow
        try
        {
            $uninstall = (invoke-command -computername $server -scriptblock { cmd /c start /wait "d:\temp\python-3.7.2-amd64.exe" /uninstall /quiet /log "d:\temp\python_uninstall.log" })
            $message = "INFO : $server uninstall cmd executed"
            logstr $message
           
            if ((test_python $server "3.7.2") -eq $false)
                 {
                  $message = "INFO: $server : Python removed"
                    logstr $message
                    write-host "$message" -ForegroundColor green

                 }
       
        }
        catch
        {
            $message = "ERROR: $server $_.exception"
            logstr $message
            write-host "$message" -ForegroundColor red
        }
   
    }
    else
    {
        $message = "INFO : $server : Python $version not present. no need to uninstall"
        logstr $message
        write-host "$message"
    }

}


function runPythonScript($server,$pythonScript,$version)
{

write-host "$server, $pythonScript, $version" -ForegroundColor DarkGreen

if (test_python $server $version)
    {
       
        if (test-path \\$server\d$\temp\)
        {
            try
            {
            copy-item \\ccepfs1024\D1C\PCSA_Setup\PCSA6.9\1092\January_Bundle_2023\pythonpackaging\${pythonScript} -Destination \\$server\d$\temp\ -force -ErrorAction stop
            $message = "INFO : copied $pythonScript to \\$server\d$\temp"
            logstr $message
            }
            catch
            {
                $message = "ERROR :$_.exception"
                logstr $message
                write-host "$_.Exception" -ForegroundColor red
            }
        }
       
        try
        {
             $installDIR = "d:\temp"
             #invoke-command -computername $server -scriptblock { $mydir = $args[0];dir $mydir; } -argumentlist $installDIR
             $command = (invoke-command -computername $server -scriptblock {$myscript = $args[0]; python d:\temp\${myscript}  } -argumentlist $pythonScript)

             if (($command | select-string "Requirement already satisfied") -or ( $command | select-string "Successfully installed"))
               {
               $message = "SUCCESS : $command"
               logstr $message
               write-host "SUCCESS " -ForegroundColor Green
               write-host "$command"
               write-host "***************"
             }
                else
                {
                $message = "WARNING: the output did not have a success message"
                write-host $message -forgroundcolor red
                logstr $message
                write-host "***************"
                }
        }
        catch
        {
            $message = "ERROR: $server $_.exception"
            logstr $message
            write-host "$message" -ForegroundColor red
        }
   
    }
    else
    {
        $message = "INFO : $server : Python $version not present. Please install first"
        logstr $message
        write-host "$message"
    }

}


