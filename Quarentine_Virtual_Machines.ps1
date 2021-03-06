# Description: Take in a list of IPs, dedupe them, change network adapter to isolated, and power down.
# Add in the PowerCLI CMDLET
Add-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
# Connect to the vCenter using passthru
Connect-VIServer 10.49.11.178 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

# input the big ip list and only store the unique ones
$IPs_UNIQ = (Get-Content "C:\Users\joseph.kordish.da\Desktop\transient\quarentine_ips_dups.txt" | Sort-Object | Get-Unique)

# Create the hash table and clear it
$MAP = @{}
$MAP.clear()

# Add a VMName to IPAddress mapping into the hash table
foreach ($vm in (get-vm | Where-Object {$_.PowerState -eq "PoweredOn"})){$MAP.Add($vm.Name,$vm.Guest.IPAddress)}

foreach ($ip in $IPs_UNIQ)
    {
        # Match up the IP to the VM
        $machine = $MAP.GetEnumerator() | where {$_.value -match $ip}
        Write-Host "Processing: $($machine.Name)"
        
        # Set a note. Store the preexisting vlan in the notes
        Set-VM -Confirm:$false -VM $machine.Name -Description "QUARENTINE - $(get-date) - $((get-vm $machine.Name | Get-NetworkAdapter | ForEach-Object {$_.NetworkName} ) -join ",") - JMK"
        
        # Set the network adapter to the non routable vlan and disconnect
        Get-VM $machine.Name | Get-NetworkAdapter | Set-NetworkAdapter -Confirm:$false -Connected:$false -NetworkAdapter "ISA-Isolated"
        
        # Try to do a gracefull poweroff. If execption then just power it off.
        try{Shutdown-VMGuest -Confirm:$false -VM $machine.Name}
          catch{Stop-VM -Confirm:$false -VM $machine.Name}
    }
