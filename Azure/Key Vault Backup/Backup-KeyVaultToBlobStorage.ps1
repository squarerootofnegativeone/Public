<#
.DESCRIPTION
This Azure Automation PowerShell runbook automates backup of keys and certificates from Azure Key Vault to Blob storage and deletes old backups from blob storage

.PARAMETER AzureKeyVaultName
	Specifies the name of the Azure Key Vault which script will backup
	
.PARAMETER StorageAccountName
	Specifies the name of the storage account where backup file will be uploaded

.PARAMETER StorageKey
	Specifies the storage key of the storage account

.PARAMETER BlobContainerName
	Specifies the container name of the storage account where backup file will be uploaded. Container will be created if it does not exist.

.PARAMETER RetentionDays
	Specifies the number of days backups are kept in blob storage. Script will remove all older files from container. 
	For this reason a container dedicated to KV backups must be used with this script.

.OUTPUTS
	Human-readable information and error messages produced during the run. Not intended to be consumed by another runbook.

.NOTES
    Hacked together from the interwebs...
    LASTEDIT: Oct 28, 2021 
    VERSION: 0.3
#>

param(
    [parameter(Mandatory=$true)]
    [String] $KeyVaultName,
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

function backup-keyVaultItems([string]$KeyVaultName, [string]$blobContainerName, $storageContext) {

    If ((test-path $backupFolder)) {
        Remove-Item $backupFolder -Recurse -Force
    }
    
    New-Item -ItemType Directory -Force -Path "$($backupFolder)\$($keyvaultName)" | Out-Null

    Write-Verbose "Starting backup of KeyVault to temp directory." -Verbose

    $certificates = Get-AzKeyVaultCertificate -VaultName $keyvaultName 
    foreach ($cert in $certificates) {
        Backup-AzKeyVaultCertificate -Name $cert.name -VaultName $keyvaultName -OutputFile "$backupFolder\$keyvaultName\certificate-$($cert.name)" | Out-Null
    }
    
    $secrets = Get-AzKeyVaultSecret -VaultName $keyvaultName
    foreach ($secret in $secrets) {
        #Exclude any secrets automatically generated when creating a cert, as these cannot be backed up   
        if (! ($certificates.Name -contains $secret.name)) {
            Backup-AzKeyVaultSecret -Name $secret.name -VaultName $keyvaultName -OutputFile "$backupFolder\$keyvaultName\secret-$($secret.name)" | Out-Null
        }
    }
    
    $keys = Get-AzKeyVaultKey -VaultName $keyvaultName
    foreach ($kvkey in $keys) {
        #Exclude any keys automatically generated when creating a cert, as these cannot be backed up   
        if (! ($certificates.Name -contains $kvkey.name)) {
            Backup-AzKeyVaultKey -Name $kvkey.name -VaultName $keyvaultName -OutputFile "$backupFolder\$keyvaultName\key-$($kvkey.name)" | Out-Null
        }
    }

    Write-Verbose "Exporting Azure Key Vault backup to storage blob" -Verbose

    foreach ($file in (get-childitem "$($backupFolder)\$($KeyVaultName)")) {
        Set-AzStorageBlobContent -File $file.FullName -Container $BlobContainerName -Blob $file.name -Context $StorageContext -Force -ErrorAction SilentlyContinue
    }
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

Write-Verbose "Starting Key Vault backup" -Verbose

$backupFolder = "$env:TEMP\azkv"
$StorageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageKey

Login
Import-Module Az.KeyVault
backup-keyVaultItems -keyvaultName $KeyVaultName -storageContext $StorageContext -blobContainerName $BlobContainerName
Remove-OldBackups -retentionDays $RetentionDays -storageContext $StorageContext -blobContainerName $BlobContainerName

Write-Verbose "Azure KeyVault backup script finished." -Verbose