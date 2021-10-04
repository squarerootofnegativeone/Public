param (
    [Parameter(Mandatory=$true)]
    [string]$tenantID,
    [Parameter(Mandatory=$true)]
    [string]$subscriptionID,
    [Parameter(Mandatory=$true)]
    [string]$RGname,
    [Parameter(Mandatory=$true)]
    [string]$nsgname,
    [Parameter(Mandatory=$true)]
    [string]$rulename,
    [Parameter(Mandatory=$true)]
    [int]$priority1,
    [Parameter(Mandatory=$true)]
    [int]$priority2
)

# Connect to Azure with authenticated account
Connect-AzAccount -SubscriptionId $subscriptionID -Tenant $tenantID

# Get the NSG resource
$nsg = Get-AzNetworkSecurityGroup -Name $nsgname -ResourceGroupName $RGname

# Add an outbound security rule to "AzureUpdateDelivery" service tag.
$nsg | Add-AzNetworkSecurityRuleConfig -Name $rulename -Access Allow `
    -Protocol TCP -Direction Outbound -Priority $priority1 -SourceAddressPrefix "virtualNetwork" -SourcePortRange * `
    -DestinationAddressPrefix "AzureUpdateDelivery" -DestinationPortRange 443

# Update the NSG.
$nsg | Set-AzNetworkSecurityGroup

# Rinse and repeat for next rule (yes this is sloppy, but I'm tired)
$nsg = Get-AzNetworkSecurityGroup -Name $nsgname -ResourceGroupName $RGname

# Add an outbound security rule to "AzureFrontDoor.FirstParty" service tag.
$nsg | Add-AzNetworkSecurityRuleConfig -Name $rulename -Access Allow `
    -Protocol TCP -Direction Outbound -Priority $priority2 -SourceAddressPrefix "virtualNetwork" -SourcePortRange * `
    -DestinationAddressPrefix "AzureFrontDoor.FirstParty" -DestinationPortRange 80

# Update the NSG.
$nsg | Set-AzNetworkSecurityGroup
