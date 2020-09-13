# New-AzVmSnapshot

## Synopsys

It receives a list of vms and takes a full snapshot for each disk of these virtual machines.

## Description

By default, the script make a snapshot for each disk of the virtual machine, however the parameter "-Disk" can be specified to limit the disk type in OsDisk or DataDisks.  

It is also possible to define the type of snapshot (Sku) generated with the option "-SkuName".  

Valid options: Standard_LRS', 'Premium_LRS' and 'Standard_ZRS'.  

The parameter -ResourceGroupName defines the resource group where all snapshots will be stored. If the resource goup does not exist and the "-Force" option is active, it will be created.  

All snapshots are genareted in the same region of the Virtual Machine.  

Snapshots are named using the following syntax:  

```
snapshot-<DIskName>-<YYYYMMDD>-<HHMM>
```

## Examples
Takes a snapshot for each disk in "vm00" and store in "RG-Snapshots" Resource Group.
```
New-AzVmSnapshot.ps1 -VMs "vm00" -ResourceGroupName RG-Snapshots
```

Take a snapshot for the OS disk of VMs vm00 and vm01, and create the resource group NewSnapshots if it does not already exist:
```
New-AzVmSnapshot.ps1 -VMs "vm00,vm01" -ResourceGroupName NewSnapshots -Disks OsDisk -Force
```

Takes a snapshot for each DataDisk in VMs vm00, vm01 and vm02, with the SKU Standard_ZRS:
```
New-AzVmSnapshot.ps1 -VMs "vm00,vm01,vm02" -SkuName Standard_ZRS -ResourceGroupName SnapshotsZRS -Force
```

More help:
```
Get-Help New-AzVmSnapshot.ps1
```