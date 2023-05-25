Custom Role to allow Start, Restart and Stop of Azure VM

To create new role use:

`New-AzRoleDefinition -InputFile "VMStartStopRole.json"`

Reference: https://learn.microsoft.com/en-us/azure/role-based-access-control/custom-roles