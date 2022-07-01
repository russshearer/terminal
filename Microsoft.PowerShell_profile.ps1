# Prompt how-to https://www.hanselman.com/blog/my-ultimate-powershell-prompt-with-oh-my-posh-and-the-windows-terminal
Import-Module Posh-Git

#oh-my-posh init pwsh --config $ENV:OneDriveCommercial\Documents\ClientConfig\oh-my-posh\themes\myterm.omp.json | Invoke-Expression
oh-my-posh init pwsh --config https://github.com/russshearer/terminal/raw/main/oh-my-posh/themes/myterm.omp.json | Invoke-Expression

# Python VENV prompt
$env:VIRTUAL_ENV_DISABLE_PROMPT = 1
$env:VIRTUAL_ENV = $VenvDir

# Default user for prompt. Will not display username and computer name for localhost for the default user
$defaultUser = $env:USERNAME

# Set Environment variable AZ_SUBSCRIPTION_NAME to current context for prompt
function Set-EnvVar { $env:AZ_SUBSCRIPTION_NAME = Get-AzContext | Select-Object -ExpandProperty "Subscription" | Select-Object -ExpandProperty "Name" }
New-Alias -Name 'Set-PoshContext' -Value 'Set-EnvVar' -Scope Global -Force

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

function repo
{
    param(
        [Parameter(Mandatory = $false)]
        [string]$RepoName,
        [Parameter(Mandatory = $false)]
        [string]$AreaName,
        [Parameter(Mandatory = $false)]
        [switch]$ListRepos
    )

    $repoBasePath = "$env:USERPROFILE\repos\"

    if ($ListRepos)
    {
        Write-Host ""
        Get-ChildItem $repoBasePath -Directory | ForEach-Object { $_.Name }
        Write-Host ""

        return
    }

    if (-not [string]::IsNullOrEmpty($RepoName))
    {
        Set-Location "$repoBasePath$($RepoName)"
    }
    else
    {
        Set-Location $repoBasePath
    }
}

function gitrepo
{
    param(
        [Parameter(Mandatory = $false)]
        [string]$RepoName,
        [Parameter(Mandatory = $false)]
        [string]$AreaName,
        [Parameter(Mandatory = $false)]
        [switch]$ListRepos
    )

    if ($ListRepos)
    {
        Write-Host ""
        #Get-ChildItem $env:USERPROFILE\Documents\development\repos\ -Directory | ForEach-Object { $_.Name }
        Get-ChildItem c:\src\ -Directory | ForEach-Object { $_.Name }
        Write-Host ""

        return
    }

    if (-not [string]::IsNullOrEmpty($RepoName))
    {
        #Set-Location "$([Environment]::GetFolderPath("MyDocuments"))\development\repos\$($RepoName)"
        Set-Location "c:\src\$($RepoName)"
    }
    else
    {
        #Set-Location "$([Environment]::GetFolderPath("MyDocuments"))\development\repos"
        Set-Location "c:\src\"
    }
}

#region Aliases

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

# Alias to edit host file
function hf
{
    Start-Process C:\Windows\system32\notepad.exe C:\Windows\System32\drivers\etc\hosts -Verb runAs
}

# Alias to Notepad
Set-Alias np 'C:\Windows\system32\notepad.exe'

# Alias for Linux ll
Set-Alias ll 'Get-ChildItem'
#endregion
