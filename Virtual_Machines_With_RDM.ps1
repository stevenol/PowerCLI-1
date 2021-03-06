# Description: Export to CSV all VirtualMachines with an RDM attached
Add-PSSnapin VMware.VimAutomation.Core
Connect-VIServer 10.0.11.179

$report = @()
$vms = Get-VM -Location Production_Test  | Get-View
foreach($vm in $vms){
   foreach($dev in $vm.Config.Hardware.Device){
      if(($dev.gettype()).Name -eq "VirtualDisk"){
         if(($dev.Backing.CompatibilityMode -eq "physicalMode") -or ($dev.Backing.CompatibilityMode -eq "virtualMode")){
         $row = "" | select VMName, Host, RDM_DeviceName, RDM_FileName, Mode
         $row.VMName = $vm.Name
         $getvm = Get-VM $row.VMName
         $row.Host = $getvm.VMHost
         $row.RDM_DeviceName = $dev.Backing.DeviceName
         $row.RDM_FileName = $dev.Backing.FileName
         $row.Mode = $dev.Backing.CompatibilityMode
         $report += $row
         }
      }
   }
}
$report | Export-Csv "c:\vms-with-RDM.csv" -NoTypeInformation -UseCulture
