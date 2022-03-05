<#
    .SYNOPSIS
    Installs pyenv-win

    .DESCRIPTION
    Installs pyenv-win to $HOME\.pyenv
    If pyenv-win is already installed, try to update to the latest version.

    .PARAMETER Uninstall
    Uninstall pyenv-win. Note that this uninstalls any Python versions that were installed with pyenv-win.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    PS> install-pyenv-win.ps1

    .LINK
    Online version: https://pyenv-win.github.io/pyenv-win/
#>
    
param (
    [Switch] $Uninstall = $False
    )
    
$PyEnvDir = "${env:USERPROFILE}\.pyenv"
$PyEnvWinDir = "${PyEnvDir}\pyenv-win"
$BinPath = "${PyEnvWinDir}\bin"
$ShimsPath = "${PyEnvWinDir}\shims"
    
Function Remove-PyEnvVars(){
    $PathParts = [System.Environment]::GetEnvironmentVariable('PATH', "User") -Split ";"
    $NewPathParts = $PathParts.Where{$_ -ne $BinPath}.Where{$_ -ne $ShimsPath}
    $NewPath = $NewPathParts -Join ";"
    [System.Environment]::SetEnvironmentVariable('PATH', $NewPath, "User")

    [System.Environment]::SetEnvironmentVariable('PYENV', $null, "User")
    [System.Environment]::SetEnvironmentVariable('PYENV_ROOT', $null, "User")
    [System.Environment]::SetEnvironmentVariable('PYENV_HOME', $null, "User")
}

Function Remove-PyEnv() {
    Write-Host "Removing $PyEnvDir..."
    If (Test-Path $PyEnvDir) {
        Remove-Item -Path $PyEnvDir -Recurse
    }
    Write-Host "Removing environment variables..."
    Remove-PyEnvVars
}

Function Get-CurrentVersion() {
    $VersionFilePath = "$PyEnvDir\.version"
    If (Test-Path $VersionFilePath) {
        $CurrentVersion = Get-Content $VersionFilePath
    } Else {
        $CurrentVersion = ""
    }

    Return $CurrentVersion
}

Function Get-LatestVersion() {
    $LatestVersionFilePath = "$PyEnvDir\latest.version"
    # TODO: Use WebClient for faster downloads
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/.version" -OutFile $LatestVersionFilePath
    $LatestVersion = Get-Content $LatestVersionFilePath

    Remove-Item -Path $LatestVersionFilePath

    Return $LatestVersion
}

Function Main() {
    If ($Uninstall) {
        Remove-PyEnv
        If ($LastExitCode -eq 0) {
            Write-Host "pyenv-win successfully uninstalled."
        } Else {
            Write-Host "Uninstallation failed."
        }
        exit
    }

    $CurrentVersion = Get-CurrentVersion()
    If ($CurrentVersion) {
        Write-Host "pyenv-win $CurrentVersion installed."
        $LatestVersion = Get-LatestVersion()
        If ($CurrentVersion -eq $LatestVersion) {
            Write-Host "No updates available."
            exit
        } Else {
            Write-Host "New version available: $LatestVersion. Updating..."
        }
    }

    New-Item -Path $PyEnvDir -ItemType Directory

    $DownloadPath = "$PyEnvDir\pyenv-win.zip"

    Invoke-WebRequest -Uri "https://github.com/pyenv-win/pyenv-win/archive/master.zip" -OutFile "$DownloadPath" -UseBasicParsing
    Expand-Archive -Path $DownloadPath -DestinationPath $PyEnvDir
    Move-Item -Path "$PyEnvDir\pyenv-win-master\*" -Destination "$PyEnvDir"
    Remove-Item -Path "$PyEnvDir\pyenv-win-master" -Recurse
    Remove-Item -Path $DownloadPath

    # Update env vars
    [System.Environment]::SetEnvironmentVariable('PYENV', "${PyEnvWinDir}\","User")
    [System.Environment]::SetEnvironmentVariable('PYENV_ROOT', "${PyEnvWinDir}\","User")
    [System.Environment]::SetEnvironmentVariable('PYENV_HOME', "${PyEnvWinDir}\","User")

    $PathParts = [System.Environment]::GetEnvironmentVariable('PATH', "User") -Split ";"

    # Remove existing paths, so we don't add duplicates
    $NewPathParts = $PathParts.Where{$_ -ne $BinPath}.Where{$_ -ne $ShimsPath}
    $NewPathParts = ($BinPath, $ShimsPath) + $NewPathParts
    $NewPath = $NewPathParts -Join ";"
    [System.Environment]::SetEnvironmentVariable('PATH', $NewPath, "User")

    &"$BinPath\pyenv.ps1" rehash

    &"$BinPath\pyenv.ps1" --version

    If ($LastExitCode -eq 0) {
        Write-Host "pyenv-win is successfully installed. You may need to close and reopen your terminal before using it."
    } Else {
        Write-Host "pyenv-win was not installed successfully. If this issue persists, please open a ticket: https://github.com/pyenv-win/pyenv-win/issues."
    }
}

Main
