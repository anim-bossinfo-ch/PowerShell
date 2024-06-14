<#
	PowerShell Profile
#>

# Import modules
# $profileDirectoryPath = Split-Path $profile
# $myModulesDirectoryPath = Join-Path $profileDirectoryPath 'mymodules'
# Get-ChildItem $myModulesDirectoryPath -Filter *.psm1 |
# ForEach-Object {
# 	Import-Module $_.FullName
# }

$customMarker = "<custom>"
$workingDirC = "C:\Transfer"
$workingDirD = "D:\Transfer"

# BossInfo

$customMarkerBI = "<customBI>"

# BOSSINFO_DMS_LOGDIR
# BOSSINFO_DMS_SERVICE_USER
# BOSSINFO_DMS_SERVICE_USER_PWD

# Install-Msi $msiFile $targetDir

function InstallMsi($msiFile, $targetDir)
{
	$startProcessParams = @{
		'FilePath'         = "$Env:SystemRoot\System32\msiexec.exe"
		'ArgumentList'     = @(
			'/qb'        
			'/i', "`"$msiFile`""
			"INSTALLFOLDER=`"$targetDir`""
		)
		'Wait'             = $true
		'PassThru'         = $true
	}
	$process = Start-Process @startProcessParams
}
Set-Alias -Name Install-Msi -Value InstallMsi -Description $customMarkerBI

function GenerateSetup($customerAbbreviation, $configuration, $platforms = 'AnyCPU')
{
	Write-Host $1
	Write-Host $configuration
	.\build\cake\build.ps1 -script .\build\cake\build.cake -target build -ScriptArgs '-Configurations="$configuration" -Platforms="$platforms" -CustomerAbbreviations="$customerAbbreviation"'
}

function GenerateSetupDebug($customerAbbreviation)
{
	GenerateSetup $customerAbbreviation 'Debug'
}

function GenerateSetupRelease($customerAbbreviation)
{
	GenerateSetup $customerAbbreviation 'Release'
}

function GenerateSetupReleaseAnyCPU($customerAbbreviation)
{
	GenerateSetup $customerAbbreviation 'Release' 'AnyCPU'
}

function GenerateSetupReleaseX86($customerAbbreviation)
{
	GenerateSetup $customerAbbreviation 'Release' 'x86'
}

function GenerateSetupTrgTen()
{
	GenerateSetup TRG 'Release'

	for (($i = 1); $i -lt 10; $i++)
	{
    	GenerateSetup TRG$i 'Release'
	}
}

Set-Alias -Name Generate-Setup-Debug -Value GenerateSetupDebug -Description $customMarkerBI
Set-Alias -Name Generate-Setup-Release -Value GenerateSetupRelease -Description $customMarkerBI
Set-Alias -Name Generate-Setup-Release-AnyCPU -Value GenerateSetupReleaseAnyCPU -Description $customMarkerBI
Set-Alias -Name Generate-Setup-Release-x86 -Value GenerateSetupReleaseX86 -Description $customMarkerBI
Set-Alias -Name Generate-Setup-TRG-10 -Value GenerateSetupTrgTen -Description $customMarkerBI

# Code Conversion
function ConvertAssemblyInfoVbRecursively()
{
	# Sample call:
	
	# cd C:\Develop\Repos\importservice-anyfiletype\source\Specific
	# Convert-AssemblyInfo-Vb-Recursively

	$files = (Get-ChildItem -Path . -Filter AssemblyInfo.vb -Recurse -ErrorAction SilentlyContinue -Force).FullName
	
	foreach ($f in $files)
	{
		C:\ProgrammeManuell\CodeConverterSingleFile\CodeConverterSingleFile.exe $f
	}
}
Set-Alias -Name Convert-AssemblyInfo-Vb-Recursively -Value ConvertAssemblyInfoVbRecursively -Description $customMarkerBI

# Services
function ModifyLocalService()
{
	param (
    	[String] $ServiceName
	)
	# Stop service
	# Set start type to manual
	# Switch the log on account

	StopServiceAndWait $ServiceName

	Set-Service -Name $ServiceName -StartupType Manual

	$username = $Env:BOSSINFO_DMS_SERVICE_USER

	$password = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Env:BOSSINFO_DMS_SERVICE_USER_PWD))
	$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force

	# $secretFile = 'C:\Admin\secrets\biDmsServicePassword'
	# $securePassword = Get-Content $secretFile | ConvertTo-SecureString
	
	$creds = New-Object -TypeName System.Management.Automation.PSCredential `
			 -ArgumentList $username, $securePassword
	
	Set-Service -Name $ServiceName -Credential $creds	
}
Set-Alias -Name Modify-Local-Service -Value ModifyLocalService -Description $customMarkerBI

# ArgumentCompleter BossInfo

$scriptBlock = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

	(Get-WmiObject -ComputerName . -Class Win32_Service).Name | Where-Object {
        $_ -like "$wordToComplete*"
    } | ForEach-Object {
          "$_"
	}
}

Register-ArgumentCompleter -CommandName ModifyLocalService -ParameterName ServiceName -ScriptBlock $scriptBlock

function StartServiceAndWait($serviceName)
{
	Start-Service $serviceName
	StartOrStopServiceAndWait $serviceName "Running"
}
Set-Alias -Name Start-Service-And-Wait -Value StartServiceAndWait -Description $customMarker

function StopServiceAndWait($serviceName)
{
	Stop-Service $serviceName
	StartOrStopServiceAndWait $serviceName "Stopped"
}
Set-Alias -Name Stop-Service-And-Wait -Value StopServiceAndWait -Description $customMarker

function StartOrStopServiceAndWait($serviceName, $targetStatus)
{
	$maxRepeat = 20
	#$searchStatus = "Running" # change to Stopped if you want to wait for services to start
	
	if ($targetStatus -eq "Running") {
		$searchStatus = "Stopped"
	}

	if ($targetStatus -eq "Stopped") {
		$searchStatus = "Running"
	}

	Write-Host $searchStatus

	do
	{
		$count = (Get-Service $serviceName | ? {$_.status -eq $searchStatus}).count
		$maxRepeat--
		Start-Sleep -Milliseconds 600
	} until ($count -eq 0 -or $maxRepeat -eq 0)
}

# Custom

function StoreSecret($outFilePath)
{
	$passwordToStore = Read-Host -AsSecureString
	$passwordToStore | ConvertFrom-SecureString | Out-File $outFilePath
}
Set-Alias -Name Store-Secret -Value StoreSecret -Description $customMarker

function GenerateFileWithRandomData($size)
{
	# https://www.meziantou.net/generate-large-files-using-powershell.htm

	# Alternative:
	# fsutil file createNew test.txt 10MB

	$fileName = [System.IO.Path]::GetFileNameWithoutExtension([System.IO.Path]::GetRandomFileName()) + ".pdf"
	#$fileName = [System.IO.Path]::GetFileNameWithoutExtension([System.IO.Path]::GetRandomFileName()) + " - $size bytes"
	$path = Join-Path $pwd $fileName
	#Write-Host $path

	$content = New-Object byte[] $size
	(New-Object System.Random).NextBytes($content)
	
	# Set-Content is very slow, use .NET method directly
	[System.IO.File]::WriteAllBytes($path, $content)
}
Set-Alias -Name Generate-File -Value GenerateFileWithRandomData -Description $customMarker

function GenerateFileNumberOf($size, $numberOf)
{
	for ($i = 1; $i -le $numberOf; $i++)
	{
		GenerateFileWithRandomData $size
	}
}
Set-Alias -Name Generate-File-Number-Of -Value GenerateFileNumberOf -Description $customMarker

function AddDefenderExclusionFolder($folderPath)
{
	Add-MpPreference -ExclusionPath $folderPath
}
Set-Alias -Name Add-Defender-Exclusion-Folder -Value AddDefenderExclusionFolder -Description $customMarker

function WhichWhere($arg)
{
	# https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/where
	where.exe $arg
}
Set-Alias -Name which -Value WhichWhere -Description $customMarker


# Docker alias
Set-Alias -Name dps -Value Get-ListOfContainer -Description $customMarker
Set-Alias -Name dcps -Value Get-ComposePs -Description $customMarker
Set-Alias -Name up -Value Invoke-ComposeUp -Description $customMarker
Set-Alias -Name down -Value Invoke-ComposeDown -Description $customMarker
Set-Alias -Name remove -Value Invoke-ComposeRemove -Description $customMarker
Set-Alias -Name stop -Value Invoke-ComposeStop -Description $customMarker
Set-Alias -Name dip -Value Get-ContainerIPAddress -Description $customMarker
Set-Alias -Name dstop -Value Invoke-ContainerStop -Description $customMarker
Set-Alias -Name drm -Value Invoke-ContainerRemove -Description $customMarker
Set-Alias -Name dlog -Value Invoke-ContainerLog -Description $customMarker
Set-Alias -Name dconn -Value Invoke-ContainerConnect -Description $customMarker
Set-Alias -Name dfimage -Value Invoke-DockerfileImage -Description $customMarker
Set-Alias -Name dstats -Value Get-DockerStats -Description $customMarker

function Get-ListOfContainer
{
	docker ps -a
}

function Invoke-ComposeUp
{
	docker-compose up -d --remove-orphans
}
function Invoke-ComposeDown
{
	docker-compose down
}

function Invoke-ComposeRemove
{
	docker-compose rm --stop --force
}

function Invoke-ComposeStop
{
	docker-compose stop
}

function Get-ComposePs
{
	docker-compose ps
}

function Get-ContainerIPAddress {
	param (
		[string] $id
	)
	& docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $id
}

function Invoke-ContainerStop
{
	param (
		[string] $id
	)
	& docker container stop $id
}

function Invoke-ContainerRemove
{
	param (
		[string] $id
	)
	& docker container rm $id
}
function Invoke-ContainerLog
{
	param (
		[string] $id
	)
	& docker logs --follow $id
}

# Argument: ImageID (docker images)
function Invoke-DockerfileImage
{
	param (
		[string] $id
	)
	& docker run -v /var/run/docker.sock:/var/run/docker.sock --rm laniksj/dfimage $id
}

function Invoke-ContainerConnect
{
	param (
		[string] $id
	)
	& docker exec -it $id /bin/bash
}

function Get-DockerStats
{
	docker stats
}

Set-Alias grep Select-String

# OS
function IsWindows
{
  return $env:OS -eq "Windows_NT"
}

function IsLinux
{
  if (IsWindows) { return $false }
  return $true
}

# ..
function fcdparent
{
  Set-Location ..
}
Set-Alias -Name .. -Value fcdparent -Description $customMarker

# edit

# $cmd = Get-ProgramFilesExecutable('Notepad++\notepad++.exe')
# Set-Alias -Name edit -Value $cmd -Description $customMarker

# ll
Set-Alias -Name ll -Value Get-ChildItem -Description $customMarker

# dirw
function dirwide
{
  Get-ChildItem | Format-Wide
}
Set-Alias -Name dirw -Value dirwide -Description $customMarker
 
# mkdir & cd
function fmkdirandcd($1)
{
  mkdir $1 | Out-Null
  cd $1
}
Set-Alias -Name mkcdir -Value fmkdirandcd -Description $customMarker

# list custom aliases
function flistcustomaliases
{
  alias | Where-Object {$_.Description -Match $customMarker}
}
Set-Alias -Name aliascust -Value flistcustomaliases -Description $customMarker

# gitignore
Function GitIgnore {
  param(
    [Parameter(Mandatory=$true)]
    [string[]]$list
  )
  $params = ($list | ForEach-Object { [uri]::EscapeDataString($_) }) -join ","
  Invoke-WebRequest -Uri "https://www.toptal.com/developers/gitignore/api/$params" | select -ExpandProperty content | Out-File -FilePath $(Join-Path -path $pwd -ChildPath ".gitignore") -Encoding ascii
}
function GitIgnoreCSharp
{
  GitIgnore csharp,visualstudio,visualstudiocode,rider
}
Set-Alias -Name gics -Value GitIgnoreCSharp -Description $customMarker

# Überschreibt current directory, wenn z.B. aus Visual Studio Terminal gestartet wird
# working dir
# if (IsWindows)
# {
#   if (Test-Path $workingDirC) {
#     cd $workingDirC
#   }
#   elseif (Test-Path $workingDirD) {
#     cd $workingDirD
#   }
# }

# ArgumentCompleter
$s = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $services = Get-Service | Where-Object {$_.Status -eq "Running" -and $_.Name -like "$wordToComplete*"}
    $services | ForEach-Object {
        New-Object -Type System.Management.Automation.CompletionResult -ArgumentList $_.Name,
            $_.Name,
            "ParameterValue",
            $_.Name
    }
}
Register-ArgumentCompleter -CommandName Stop-Service -ParameterName Name -ScriptBlock $s

# oh-my-posh
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/freax.json" | Invoke-Expression