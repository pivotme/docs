Import-Module Vmware.VimAutomation.Core
Write-Host "Create datastores.txt file on the Desktop and enter the Datastore Names in the separate lines"
$errors = @()
$output = @()
$vmhosts = @()
$vms = @()
$vc = Read-Host "Enter the Name of Vcenter Server you want to login :"
Connect-VIServer $vc
$datastores = Get-Content "$home\desktop\datastores.txt"
if ( -not $datastores){
	Write-Host "No input provided in the file"
	Exit
}
foreach($datastore in $datastores){
	$temp = "" | select Datastore, Comments
	$temp.Datastore = $datastore
	$ds = Get-Datastore $datastore -ErrorAction SilentlyContinue -ErrorVariable e
	if( -not $ds){
		Write-Host "Datastore with Name $datastore not found" -ForegroundColor Green
		$errors += $e
		$temp.Comments = "Datastore Not Found"
	}
	if($ds){
		Write-Host "Datastore $datastore found Looking for Accessibility" -ForegroundColor Yellow
		if( $ds.Accessible -eq $False ){
			Write-Host "Datastore with Name $datastore is not accessible to any host in the cluster" -ForegroundColor Green
			$temp.Comments = "Datastore Found with Unmounted and Inactive State"
		}
		if( $ds.Accessible -eq $True ){
			$attachedHosts = $ds.ExtensionData.Host
			$vmhost = Get-VMHost -Id $attachedHosts.Key | select Name, @{N="Datastore";E={$ds.Name}}
			$vmhosts += $vmhost
			Write-Host "Datastore Attached to Hosts, Check file Attached-Host-Consolidated.csv on the desktop" -ForegroundColor Yellow
			Write-Host "Checking for VMs List" -ForegroundColor Yellow
			$vm = $ds | Get-VM | select Name, State, @{N="Datastore";E={$ds.Name}}
			$vms += $vm
			if($vm){
				Write-Host "VMs found on the datastore $datastore, list exported to Running-VM-Consolidated.csv on the desktop DO NOT DELETE this lun" -ForegroundColor Red
				$temp.Comments = "Datastore active with running VMs Please check the Running-VM-Consolidated.csv file"
			}
			else {
				Write-Host "No VMs found on this Datastore, this Datastore is safe to be unmounted and detached" -ForegroundColor Green
				$temp.Comments = "Datastore active with no VMs, please check Attached-Host-Consolidated.csv and unmount the DS"
			}
		}
	}
	$output += $temp
}
$vmhosts | export-Csv "$HOME\Desktop\Attached-Host-Consolidated.csv" -NotypeInformation
$vms | export-Csv "$HOME\Desktop\Running-VM-Consolidated.csv" -NotypeInformation
$output | Export-Csv "$home\desktop\output.csv" -NoTypeInformation
$errors | Export-Csv "$home\desktop\errors.csv" -NoTypeInformation
Read-Host "Press Enter to Exit"