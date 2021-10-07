#Connect to VicPol Azure tenant and print all VNet peers for subscriptions starting with "vicpol"
Connect-AzAccount -TenantId '59aab5f9-7fdb-4dfd-89dd-0f4a2651f587'

$sublist = Get-AzSubscription -TenantId '59aab5f9-7fdb-4dfd-89dd-0f4a2651f587'
foreach ($sub in $sublist) {
     if ($sub.name -like 'vicpol*') {
        Write-Output 'Subscription Name:' $sub.name
        Get-AzVirtualNetwork | Select-Object Name, VirtualNetworkPeerings
        }
}