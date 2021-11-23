<#
.DESCRIPTION
This Azure Automation PowerShell runbook automates backup of Azure Firewall configuration to Blob storage and deletes old backups from blob storage

.PARAMETER SubscriptionName
	Specifies the name of the subscription where the Azure Firewall is located

.PARAMETER ResourceGroupName
	Specifies the name of the resource group where the Azure Firewall is located

.PARAMETER FirewallName
	Specifies the name of the Azure Firewall which script will backup
	
.PARAMETER StorageAccountName
	Specifies the name of the storage account where backup file will be uploaded

.PARAMETER StorageKey
	Specifies the storage key of the storage account

.PARAMETER BlobContainerName
	Specifies the container name of the storage account where backup file will be uploaded. Container will be created if it does not exist.

.PARAMETER RetentionDays
	Specifies the number of days backups are kept in blob storage. Script will remove all older files from container. 
	For this reason a container dedicated to Firewall backups must be used with this script.

.OUTPUTS
	Human-readable information and error messages produced during the run. Not intended to be consumed by another runbook.

.NOTES
    Heavily based on https://github.com/francescomolfese/Microsoft/tree/master/Azure%20Firewall%20Backup
    LASTEDIT: Nov 3, 2021 
    VERSION: 0.1
#>

param(
	[parameter(Mandatory=$true)]
    [String] $ResourceGroupName,
    [parameter(Mandatory=$true)]
    [String] $FirewallName,
    [parameter(Mandatory=$true)]
    [String]$StorageAccountName,
    [parameter(Mandatory=$true)]
    [String]$StorageKey,
    [parameter(Mandatory=$true)]
    [string]$BlobContainerName,
    [parameter(Mandatory=$true)]
    [Int32]$RetentionDays
)

$ErrorActionPreference = 'stop'

function Login() {
	$connectionName = "AzureRunAsConnection"
	try
	{
		$servicePrincipalConnection = Get-AutomationConnection -Name $connectionName         

		Write-Verbose "Logging in to Azure..." -Verbose

		Connect-AzAccount `
			-ServicePrincipal `
			-TenantId $servicePrincipalConnection.TenantId `
			-ApplicationId $servicePrincipalConnection.ApplicationId `
			-CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint | Out-Null
	}
	catch {
		if (!$servicePrincipalConnection)
		{
			$ErrorMessage = "Connection $connectionName not found."
			throw $ErrorMessage
		} else{
			Write-Error -Message $_.Exception
			throw $_.Exception
		}
	}
}

function backup-azFirewall([string]$FirewallName, [string]$blobContainerName, $storageContext) {

    If ((test-path $backupFolder)) {
        Remove-Item $backupFolder -Recurse -Force
    }
    
    New-Item -ItemType Directory -Force -Path "$($backupFolder)\$($FirewallName)" | Out-Null

    Write-Verbose "Starting backup of Azure Firewall to temp directory." -Verbose

    $BackupFilename = $FirewallName + (Get-Date).ToString("yyyyMMddHHmm") + ".json"
    $BackupFilePath = ($backupFolder + $BackupFilename)
    $AzureFirewallId = (Get-AzFirewall -Name $FirewallName -ResourceGroupName $resourceGroupName).id

    Export-AzResourceGroup -ResourceGroupName $resourceGroupName -Resource $AzureFirewallId -SkipAllParameterization -Path $BackupFilePath
    
    Write-Verbose "Exporting Azure Firewall backup to storage blob" -Verbose
    Set-AzStorageBlobContent -File $BackupFilePath -Blob $BackupFilename -Container $blobContainerName -Context $storageContext -Force -ErrorAction SilentlyContinue
}

function Remove-OldBackups([int]$retentionDays, [string]$blobContainerName, $storageContext) {
	Write-Output "Removing backups older than '$retentionDays' days from blob: '$blobContainerName'"
	$isOldDate = [DateTime]::UtcNow.AddDays(-$retentionDays)
	$blobs = Get-AzStorageBlob -Container $blobContainerName -Context $storageContext
	foreach ($blob in ($blobs | Where-Object { $_.LastModified.UtcDateTime -lt $isOldDate -and $_.BlobType -eq "BlockBlob" })) {
		Write-Verbose ("Removing blob: " + $blob.Name) -Verbose
		Remove-AzStorageBlob -Blob $blob.Name -Container $blobContainerName -Context $storageContext
	}
}

Write-Verbose "Starting Firewall backup" -Verbose

$backupFolder = "$env:TEMP\azfw\"
$StorageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageKey

Login
Import-Module Az.Network
Import-Module Az.Resources
backup-azFirewall -keyvaultName $KeyVaultName -storageContext $StorageContext -blobContainerName $BlobContainerName
Remove-OldBackups -retentionDays $RetentionDays -storageContext $StorageContext -blobContainerName $BlobContainerName

Write-Verbose "Azure Firewall backup script finished." -Verbose