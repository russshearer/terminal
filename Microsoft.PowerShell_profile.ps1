# Set PSModulePath
#$env:PSModulePath = "C:\Users\Russ\PowerShell\Modules;C:\Program Files\PowerShell\Modules;c:\program files\powershell\7\Modules;C:\Program Files\WindowsPowerShell\Modules;C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules"

# Prompt how-to https://www.hanselman.com/blog/my-ultimate-powershell-prompt-with-oh-my-posh-and-the-windows-terminal

# Import modules, Install if needed
$modules = @("Posh-Git", "Terminal-Icons", "Az.Tools.Predictor")

foreach ($module in $modules)
{
    if (Get-Module -ListAvailable -Name $module)
    {
        Import-Module $module
    }
    else {
        Write-Host "Installing module $module"
        Install-Module -Name $module
        Import-Module -Name $module
    }
}

# Prompt settings
oh-my-posh init bash --config https://raw.githubusercontent.com/russshearer/terminal/refs/heads/main/oh-my-posh/myterm.omp.json | Invoke-Expression

# Python VENV prompt
$env:VIRTUAL_ENV_DISABLE_PROMPT = 1
$env:VIRTUAL_ENV = $VenvDir

# Default user for prompt. Will not display username and computer name for localhost for the default user
$defaultUser = $env:USERNAME

# Set Environment variable AZ_SUBSCRIPTION_NAME to current context for prompt
function Set-EnvVar { $env:AZ_SUBSCRIPTION_NAME = Get-AzContext | Select-Object -ExpandProperty "Subscription" | Select-Object -ExpandProperty "Name" }
New-Alias -Name 'Set-PoshContext' -Value 'Set-EnvVar' -Scope Global -Force

# Root folder of gitrepos
$gitRepoHome = "c:\src"

function Check-UpdateModules
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Version,
        [
        Parameter(
            ValueFromPipeline = $false,
            HelpMessage = "Show Modules with updates only"
        )
        ]
        [switch]
        $ShowUpdatesOnly
    )

    Write-Host "Getting installed modules"
    $mods = Get-InstalledModule

    Write-Host "Checking $($mods.Count) installed modules for updates. " -NoNewline

    # Skip modules without updates
    if ($ShowUpdatesOnly)
    {
        Write-Host "Showing only modules needing updates"
    }
    else
    {
        Write-Host ""
    }

    foreach ($mod in $mods)
    {
        $latestAvailable = Find-Module $mod.Name

        if ($mod.version -eq $latestAvailable.version)
        {
            # Skip modules without updates
            if ($ShowUpdatesOnly)
            {
                Continue
            }

            $color = "green"
            $text = "Latest available version match current installed"
        }
        else
        {
            $color = "magenta"
            $text = "Latest available version is higher than the current installed"
        }

        Write-Host "$($mod.Name) – $($mod.version) [$text $($latestAvailable.version)]" -foregroundcolor $color
    }
}

# Get for updates
function Get-WingetUpgrades {
    class Software {
        [string]$Name
        [string]$Id
        [string]$Version
        [string]$AvailableVersion
    }

    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $upgradeResult = winget upgrade | Out-String

    $lines = $upgradeResult.Split([Environment]::NewLine)

    # Find the line that starts with Name, it contains the header
    $fl = 0
    while (-not $lines[$fl].StartsWith("Name")) {
        $fl++
    }

    # Line $i has the header, we can find char where we find ID and Version
    $idStart = $lines[$fl].IndexOf("Id")
    $versionStart = $lines[$fl].IndexOf("Version")
    $availableStart = $lines[$fl].IndexOf("Available")
    $sourceStart = $lines[$fl].IndexOf("Source")

    # Now cycle in real package and split accordingly
    $upgradeList = @()
    for ($i = $fl + 1; $i -le $lines.Length; $i++) {
        $line = $lines[$i]
        if ($line.Length -gt ($availableStart + 1) -and -not $line.StartsWith('-')) {
            $name = $line.Substring(0, $idStart).TrimEnd()
            $id = $line.Substring($idStart, $versionStart - $idStart).TrimEnd()
            $version = $line.Substring($versionStart, $availableStart - $versionStart).TrimEnd()
            $available = $line.Substring($availableStart, $sourceStart - $availableStart).TrimEnd()
            $software = [Software]::new()
            $software.Name = $name;
            $software.Id = $id;
            $software.Version = $version
            $software.AvailableVersion = $available;

            $upgradeList += $software
        }
    }

    return $upgradeList
}

# List repos
function listRepos
{
    $repoArt = "
  ___   _   _       ___
 / __| (_) | |_    | _ \  ___   _ __   ___   ___
| (_ | | | |  _|   |   / / -_) | '_ \ / _ \ (_-<
 \___| |_|  \__|   |_|_\ \___| | .__/ \___/ /__/
                               |_|"

    Write-Host $repoArt

    #Get-ChildItem $env:USERPROFILE\Documents\development\repos\ -Directory | ForEach-Object { $_.Name }
    Get-ChildItem -Directory $gitRepoHome | ForEach-Object { $_.Name }
    Write-Host ""

    return
}

# Change folder to root of repos if no repo specified, otherwiese change to the root of the repo folders
Set-Alias gitrepo 'repo'
function repo
{
    param(
        [Parameter(Mandatory = $false)]
        [string]$RepoName,
        [Parameter(Mandatory = $false)]
        [string]$AreaName
    )

    if (-not [string]::IsNullOrEmpty($RepoName))
    {
        #Set-Location "$([Environment]::GetFolderPath("MyDocuments"))\development\repos\$($RepoName)"
        try
        {
            Set-Location "$($gitRepoHome)\$($RepoName)" -ErrorAction:Stop
        }
        catch
        {
            Write-Host "A repo was not found at $($gitRepoHome)\$($RepoName), searching for a match"  -ForegroundColor Red

            # Does repo name start with passed value
            $repos = Get-ChildItem -Directory $gitRepoHome
            $matched = $false

            foreach ($b in $repos)
            {

                $path = $b.PSPath.Split("::")[1].ToLower()
                $folder = ($gitRepoHome + "\" + $RepoName).ToLower()

                if ($path.StartsWith($folder))
                {
                    Write-Host "Found match with $($path), switching" -ForegroundColor Yellow
                    Set-Location $path
                    $matched = $true
                    Break
                }
                else
                {
                    $matched = $false
                }
            }

            if (-Not $matched)
            {
                Write-Host "No matches found, printing list of repos at $($gitRepoHome)" -NoNewline
                listRepos
            }
        }
    }
    else
    {
        #Set-Location "$([Environment]::GetFolderPath("MyDocuments"))\development\repos"
        listRepos
        Set-Location $gitRepoHome
    }
}

<#
	.SYNOPSIS
		Displays an object's values and the 'dot' paths to them

	.DESCRIPTION
		A detailed description of the Display-Object function.

	.PARAMETER TheObject
		The object that you wish to display

	.PARAMETER depth
		the depth of recursion (keep it low!)

	.PARAMETER Avoid
		an array of names of pbjects or arrays you wish to avoid.

	.PARAMETER Parent
		For internal use, but you can specify the name of the variable

	.PARAMETER CurrentDepth
		For internal use

	.NOTES
		Additional information about the function.
#>
function Display-Object
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $InputObject,
        [int]$depth = 5,
        [Object[]]$Avoid = @('#comment'),
        [string]$Parent = '$',
        [int]$CurrentDepth = 0
    )

    if (($CurrentDepth -ge $Depth) -or ($InputObject -eq $Null)) { return; } #prevent runaway recursion

    $ObjectTypeName = $InputObject.GetType().Name #find out what type it is

    if ($ObjectTypeName -in 'HashTable', 'OrderedDictionary')
    {
        #If you can, force it to be a PSCustomObject
        $InputObject = [pscustomObject]$InputObject;
        $ObjectTypeName = 'PSCustomObject'
    }

    #first do objects that cannot be treated as an array.
    if ($InputObject.Count -le 1 -and $ObjectTypeName -ne 'object[]')
    {
        #not something that behaves like an array
        # figure out where you get the names from
        if ($ObjectTypeName -in @('PSCustomObject'))  # Name-Value pair properties created by Powershell
        {
            $MemberType = 'NoteProperty'
        }
        else
        {
            $MemberType = 'Property'
        }

        #now go through the names
        $InputObject | gm -MemberType $MemberType | Where-Object { $_.Name -notin $Avoid } |

        ForEach-Object
        {
            Try
            {
                $child = $InputObject.($_.Name);
            }
            catch
            {
                $Child = $null
            } # avoid crashing on write-only objects

            $brackets = '';
            if ($_.Name -like '*.*')
            {
                $brackets = "'"
            }

            #is the current child a value or a null?
            if ($child -eq $null -or $child.GetType().BaseType.Name -eq 'ValueType' -or $child.GetType().Name -in @('String', 'String[]'))
            {
                [pscustomobject]@{ 'Path' = "$Parent.$brackets$($_.Name)$brackets"; 'Value' = $Child; }
            }
            elseif (($CurrentDepth + 1) -eq $Depth)
            {
                [pscustomobject]@{ 'Path' = "$Parent.$brackets$($_.Name)$brackets"; 'Value' = $Child; }
            }
            else
            {
                #not a value but an object of some sort
                Display-Object -TheObject $child -depth $Depth -Avoid $Avoid `
                    -Parent "$Parent.$brackets$($_.Name)$brackets" `
                    -CurrentDepth ($currentDepth + 1)
            }
        }
    }
    else
    {
        #it is an array
        if ($InputObject.Count -gt 0)
        {
            0..($InputObject.Count - 1) | Foreach {
                $child = $InputObject[$_];

                #is the current child a value or a null? if so display it
                if (($child -eq $null) -or ($child.GetType().BaseType.Name -eq 'ValueType') -or ($child.GetType().Name -in @('String', 'String[]')))
                {
                    [pscustomobject]@{ 'Path' = "$Parent[$_]"; 'Value' = "$($child)"; }
                }
                elseif (($CurrentDepth + 1) -eq $Depth)
                {
                    [pscustomobject]@{ 'Path' = "$Parent[$_]"; 'Value' = "$($child)"; }
                }
                else
                {
                    #not a value but an object of some sort so do a recursive call
                    Display-Object -TheObject $child -depth $Depth -Avoid $Avoid -parent "$Parent[$_]" `
                        -CurrentDepth ($currentDepth + 1)
                }

            }
        }
        else
        {
            [pscustomobject]@{ 'Path' = "$Parent"; 'Value' = $Null }
        }
    }
}

#region Aliases
# Downloads alias
function dl
{
    Set-Location "$env:USERPROFILE\Downloads"
}

# Onedrive alias
function od
{
    Set-Location $env:OneDrive
}

# Change folder to current users 'My Documents\development folder'
function dev
{
    Set-Location "$([Environment]::GetFolderPath("MyDocuments"))\development"
}

# Desktop alias
function dt
{
    Set-Location $([Environment]::GetFolderPath("Desktop"))
}

# Documents folder alias
function docs
{
    Set-Location $([Environment]::GetFolderPath("MyDocuments"))
}

# Alias to edit host file
function hf
{
    Start-Process C:\Windows\system32\notepad.exe C:\Windows\System32\drivers\etc\hosts -Verb runAs
}

# Edit PowerShell profile
function ep
{
    code $PROFILE
}

# Reload PowerShell profile
function rlp
{
    . $PROFILE
    Write-Host "PowerShell profile reloaded!" -ForegroundColor Green
}

# Get weather information
function weather
{
    param(
        [Parameter(Mandatory = $false)]
        [string]$City = ""
    )

    if ($City)
    {
        (Invoke-WebRequest "https://wttr.in/$City" -UserAgent "curl").Content
    }
    else
    {
        (Invoke-WebRequest "https://wttr.in/" -UserAgent "curl").Content
    }
}

# Alias to Azure CLI in Docker
function azd() {
    docker run -it mcr.microsoft.com/azure-cli
}

# Alias to Notepad
Set-Alias np 'C:\Windows\system32\notepad.exe'

# Alias for Linux ll
Set-Alias ll 'Get-ChildItem'
#endregion

# PSReadLine settings
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
