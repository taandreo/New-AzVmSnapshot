########################################################################
##
## New-AzVmSnapshot
##
## Author: Tairan Andreo (taandreo@hotmail.com)
##
## Version 1.0 
##
########################################################################


<#
.SYNOPSIS

It receives a list of vms and takes a full snapshot for each disk of these virtual machines.

.DESCRIPTION

By default, the script make a snapshot for each disk of the virtual machine, however the 
parameter "-Disk" can be specified to limit the disk type in OsDisk or DataDisks.

It is also possible to define the type of snapshot (Sku) generated with the option "-SkuName".

Valid options: Standard_LRS', 'Premium_LRS' and 'Standard_ZRS'.

The parameter -ResourceGroupName defines the resource group where all snapshots will be stored.
If the resource goup does not exist and the "-Force" option is active, it will be created.

All snapshots are genareted in the same region of the Virtual Machine.

Snapshots are named using the following syntax:

snapshot-<DIskName>-<YYYYMMDD>-<HHMM>

.EXAMPLE 
New-AzVmSnapshot.ps1 -VMs "vm00" -ResourceGroupName RG-Snapshots

Takes a snapshot for each disk in "vm00" and store in "RG-Snapshots" Resource Group.

.EXAMPLE
New-AzVmSnapshot.ps1 -VMs "vm00,vm01" -ResourceGroupName NewSnapshots -Disks OsDisk -Force

Take a snapshot for the OS disk of VMs vm00 and vm01, and create the resource group NewSnapshots 
if it does not already exist.

.EXAMPLE
New-AzVmSnapshot.ps1 -VMs "vm00,vm01,vm02" -SkuName Standard_ZRS -ResourceGroupName SnapshotsZRS -Force

Takes a snapshot for each DataDisk in VMs vm00, vm01 and vm02, with the SKU Standard_ZRS.
#>


param (
    [Parameter(Mandatory=$true)]
    [string]$VMs,
    [Parameter(Mandatory=$false)]
    [switch]$Force,
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory=$false)]
    [ValidateSet('DataDisks','OsDisk','All')]
    [string]$Disks = "All",
    [Parameter(Mandatory=$false)]
    [ValidateSet('Standard_LRS','Premium_LRS','Standard_ZRS')]
    [string]$SkuName = "Standard_LRS"
)


$vmNameList = $VMs.Split(",")
$vmList = @()

foreach ($vmName in $vmNameList) {

    $vm = Get-AzVM | Where-Object {$_.Name -like $vmName}
    if($null -eq $vm){
        if($Force -eq $false){
            Write-Error -Message "Virtual Machine $vmName does not exist, canceling script execution."
            Exit
        }
        else {
            Write-Warning -Message "Virtual Machine $vmName does not exist. Skipping to the next item..."
        }
    }
    else {
        $vmList += $vm
    }
}

# Checks if the resource group exists
Get-AzResourceGroup -Name $ResourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue > $null

if ($notPresent)
{
    if($Force){
        Write-Host "Resource Group $ResourceGroupName does not exist in this subscription, creating resource group ... " -NoNewline
        New-AzResourceGroup -Name $ResourceGroupName -Location $vmList[0].Location > $null
        Write-Host "Created !" -ForegroundColor Green
    }
    else{
        Write-Error -Message "Resource Group $ResourceGroupName does not exist in this subscription, canceling script execution."
        Exit
    }
}

foreach($vm in $vmList){
    $location = $vm.Location
    $OsDisk = $vm.StorageProfile.OsDisk
    $DataDisks = $vm.StorageProfile.DataDisks
    $AllDisks = @()

    if($Disks -eq "All"){
        $AllDisks += $OsDisk
        $AllDisks += $DataDisks
    }
    elseif($Disks -eq "OsDisk"){
        $AllDisks = $OsDisk
    }
    elseif($Disks -eq "DataDisks"){
        if($DataDisks.Count -eq 0){
            $VmName = $vm.name
            Write-Warning "The virtual machine $VmName has no data disks."
        }
        $AllDisks = $DataDisks
    }
    
    $date = $(Get-Date -format yyyyMMdd-HHmm)
    
    foreach($Disk in $AllDisks){
        $DiskName = $Disk.Name
        $SnapshotName = "snapshot-$DiskName-$date"
        $DiskId = $Disk.ManagedDisk.Id
        $snapshotConfig = New-AzSnapshotConfig -Location $location -SourceUri $DiskId -SkuName $SkuName -CreateOption Copy
        Write-Host "Creating $SnapshotName ... " -NoNewline
        New-AzSnapshot -ResourceGroupName $ResourceGroupName -SnapshotName $SnapshotName -Snapshot $snapshotConfig > $null
        Write-Host "Created !" -ForegroundColor Green
    }
    
}