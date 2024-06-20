<#
	PowerShell Profile BossInfo
#>

$customMarkerBI = "<customBI>"

# ListCustomAliasesBossInfo

function ListCustomAliasesBossInfo
{
  flistcustomaliasesForMarker $customMarkerBI
}

Set-Alias -Name List-Custom-Aliases-BossInfo -Value ListCustomAliasesBossInfo -Description $customMarker

# Environment variables

# BOSSINFO_DMS_LOGDIR
# BOSSINFO_DMS_SERVICE_USER
# BOSSINFO_DMS_SERVICE_USER_PWD

function ListBossInfoEnvironmentVariables
{
	Write-Host "BOSSINFO_DMS_LOGDIR`t$env:BOSSINFO_DMS_LOGDIR"
	Write-Host "BOSSINFO_DMS_SERVICE_USER`t$env:BOSSINFO_DMS_SERVICE_USER"
	Write-Host "BOSSINFO_DMS_SERVICE_USER_PWD`t$env:BOSSINFO_DMS_SERVICE_USER_PWD"
}

Set-Alias -Name List-BossInfo-Environment-Variables -Value ListBossInfoEnvironmentVariables -Description $customMarker

function SetBossInfoEnvironmentVariables
{
	$envVarName = 'BOSSINFO_DMS_LOGDIR'
	$default = 'C:\Logs'
	if (!($value = Read-Host "Please enter $envVarName [Default <Enter> = $default]")) { $value = $default }
	Write-Host "Setting environment variable..."
	[Environment]::SetEnvironmentVariable($envVarName, $value, "Machine")
	
	$envVarName = 'BOSSINFO_DMS_SERVICE_USER'
	$default = '.\dgService'
	if (!($value = Read-Host "Please enter $envVarName [Default <Enter> = $default]")) { $value = $default }
	Write-Host "Setting environment variable..."
	[Environment]::SetEnvironmentVariable($envVarName, $value, "Machine")
	
	$envVarName = 'BOSSINFO_DMS_SERVICE_USER_PWD'
	$default = ''
	$value = Read-Host "Please enter $envVarName" -MaskInput
	$valueEncoded = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($value))
	Write-Host "Setting environment variable..."
	[Environment]::SetEnvironmentVariable($envVarName, $valueEncoded, "Machine")
}

Set-Alias -Name Set-BossInfo-Environment-Variables -Value SetBossInfoEnvironmentVariables -Description $customMarker

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
	
	Start-Process @startProcessParams
	#$process = Start-Process @startProcessParams
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

function GenerateSetupRelease()
{
	param (
    	[String] $CustomerAbbreviation
	)

	GenerateSetup $CustomerAbbreviation 'Release'
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

$scriptBlockCustAbbr = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

	$specificDir = GetSpecificDir

	GetSpecificCustomerAbbreviations $specificDir | Where-Object {
        $_ -like "$wordToComplete*"
    } | ForEach-Object {
          "$_"
	}
}

Register-ArgumentCompleter -CommandName GenerateSetupDebug -ParameterName CustomerAbbreviation -ScriptBlock $scriptBlockCustAbbr
Register-ArgumentCompleter -CommandName GenerateSetupRelease -ParameterName CustomerAbbreviation -ScriptBlock $scriptBlockCustAbbr
Register-ArgumentCompleter -CommandName GenerateSetupReleaseAnyCPU -ParameterName CustomerAbbreviation -ScriptBlock $scriptBlockCustAbbr
Register-ArgumentCompleter -CommandName GenerateSetupReleaseX86 -ParameterName CustomerAbbreviation -ScriptBlock $scriptBlockCustAbbr

function GetSpecificDir
{
	Get-ChildItem . -Directory -recurse -Filter specific 
}

function GetSpecificCustomerAbbreviations($specificDir)
{
	(Get-ChildItem $specificDir).Name
}

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

	Write-Host "ServiceName: $ServiceName"

	Write-Host "Stopping..."

	StopServiceAndWait $ServiceName

	Write-Host "Set start type to manual..."

	Set-Service -Name $ServiceName -StartupType Manual

	Write-Host "Switch the log on account..."

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

$scriptBlock = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

	(Get-WmiObject -ComputerName . -Class Win32_Service).Name | Where-Object {
        $_ -like "$wordToComplete*"
    } | ForEach-Object {
          "$_"
	}
}

Register-ArgumentCompleter -CommandName ModifyLocalService -ParameterName ServiceName -ScriptBlock $scriptBlock