# Azure Key Vault Items Backup
This Azure Automation Runbook automates the backup of items in an Azure Key Vault to blob storage. Also deletes previous backups older than specified retention date.

* Requires Azure Automation Account to have an [Azure Run As account](https://docs.microsoft.com/en-us/azure/automation/create-run-as-account) with default `AzureRunAsConnection` connection
* Key Vault needs an [Access Policy](https://docs.microsoft.com/en-us/azure/key-vault/general/assign-access-policy) to allow the Azure Run As account to do anything useful with the vault

:rocket:

## PARAMETERS
### KeyVaultName
    Specifies the name of the Key Valut for backup

### StorageAccountName
    Specifies the name of the storage account that will hold backup files

### StorageKey
	Specifies the storage key of the storage account

### BlobContainerName
	Specifies the container name of the storage account where backup file will be uploaded.
    Container will be created if it does not exist.

### RetentionDays
	Specifies the number of days backups are kept in blob storage. Script will remove all older files from container.
    For this reason a container dedicated to KV backups must be used with this script.

