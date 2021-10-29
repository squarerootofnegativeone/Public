# Deploy KeyVault with randomised name to a Resource Group

# Define parameters
param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    [Parameter(Mandatory=$true)]
    [string]$TenandId,
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId
)

# Connect to Azure
Connect-AzAccount -TenantId $TenandId -SubscriptionId $SubscriptionId

# Get location of RG - dunno is this is strictly necessary for New-AzKeyVault
$rg = Get-AzResourceGroup -Name $ResourceGroup

# Generate random alphanumeric string with length of $length
$length = 16
$rnd = ""; do { $rnd = $rnd + ((0x30..0x39) + (0x41..0x5A) + (0x61..0x7A) | Get-Random | ForEach-Object {[char]$_}) } until ($rnd.length -eq $length)

# Concatenate kv and random string to generate name for new Key Vault
$kvname = "kv"+$rnd

# No prizese for guessing what this cmdlet does...
New-AzKeyvault -name $kvname -ResourceGroupName $ResourceGroup -Location $rg.location -EnabledForDiskEncryption