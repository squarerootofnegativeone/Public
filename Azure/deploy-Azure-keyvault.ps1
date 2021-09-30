param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$location
)

$length = 16
$rnd = ""; do { $rnd = $rnd + ((0x30..0x39) + (0x41..0x5A) + (0x61..0x7A) | Get-Random | % {[char]$_}) } until ($rnd.length -eq $length)
$kvname = "kv"+$rnd

New-AzKeyvault -name $kvname -ResourceGroupName $ResourceGroup -Location $location -EnabledForDiskEncryption