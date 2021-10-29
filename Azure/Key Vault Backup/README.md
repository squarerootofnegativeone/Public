# Azure Key Vault Items Backup
    This Azure Automation Runbook automates the backup of items in an Azure Key Vault to blob storage.
    Also deletes any previous backups older than retention date.

## PARAMETERS
### KeyVaultName
    Specifies the name of the Key Valut for backup

### StorageAccountName
    Specifies the name of the storae account that will hold backup files

### StorageKey
	Specifies the storage key of the storage account

### BlobContainerName
	Specifies the container name of the storage account where backup file will be uploaded.
    Container will be created if it does not exist.

### RetentionDays
	Specifies the number of days backups are kept in blob storage. Script will remove all older files from container.
    For this reason a container dedicated to KV backups must be used with this script.

## OUTPUTS
	Human-readable informational and error messages produced during execution. Not intended to be consumed by another runbook.

## NOTES
    Hacked together from the interwebs...
    LASTEDIT: Oct 28, 2021 
    VERSION: 0.3