# Azure Firewall Backup
This Azure Automation Runbook automates the backup of an Azure Firewall to blob storage. Also deletes previous backups older than specified retention date.

* Requires Azure Automation Account to have an [Azure Run As account](https://docs.microsoft.com/en-us/azure/automation/create-run-as-account) with default `AzureRunAsConnection` connection

:joystick:

## PARAMETERS
### Resource Group Name
    Specifies the name of the resource group where the Azure Firewall is located
    
### FirewallName
    Specifies the name of the Azure Firewall to be backed-up

### StorageAccountName
    Specifies the name of the storage account that will hold backup files

### StorageKey
	Specifies the storage key of the storage account

### BlobContainerName
	Specifies the container name of the storage account where backup file will be uploaded.
  Container will be created if it does not exist.

### RetentionDays
	Specifies the number of days backups are kept in blob storage. Script will remove all older files from container.
  For this reason a container dedicated to Azure Firewall backups must be used with this script.

