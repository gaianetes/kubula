# Terraform for provisioning hyperv resources

## Prerequisites

A few configuration changes need to be enabled on the host Windows Server where the hyperv resources will be created. First, make sure that `winrm` is enabled and running. Then, for the purpose of this demo, you will need to enable http traffic for the remote Terraform machine to be able to connect to (this is quite insecure, TLS certificates should be generated and configured both on the client and server, however, this is out of scaope for this demo). This can be done by issuing the following command(s) in `powershell`:

> ```powershell
> winrm create winrm/config/Listener?Address=*+Transport=HTTP
> winrm set winrm/config/service/auth @{Basic="true"}
> winrm set winrm/config/service @{AllowUnencrypted="true"}
> ```

### Important Considerations

- Enabling HTTP transport and allowing unencrypted traffic can pose security risks. Ensure this is suitable for your environment, especially if sensitive data is being transmitted.
- For more secure communication, consider using HTTPS transport by creating a listener for HTTPS and configuring certificates.

By following these steps, you can enable HTTP transport for WinRM on Windows Server 2019.

## Networking

In order to get access to the open internet, you must first create a virtual switch which can then be attached to machine instances. First take note of the adapters you have available on your system by running the following `powershell` command:

```powershell
Get-NetAdapter | Select-Object Name
```

In Hyper-V, a physical network adapter cannot be directly attached to multiple virtual switches simultaneously. However, you can achieve a similar result by using VLANs or creating multiple virtual network adapters (vNICs) bound to the same physical adapter and then assigning these vNICs to different virtual switches.

### Using VLANs

1. Create the First Virtual Switch
> ```powershell
> New-VMSwitch -Name "VMSwitch1" -NetAdapterName "PhysicalAdapterName" -AllowManagementOS $true
> ```
2. Create the Second Virtual Switch with a Different VLAN ID
> ```powershell
> `New-VMSwitch -Name "VMSwitch2" -NetAdapterName "PhysicalAdapterName" -VlanId 2
> ```

### Using Multiple Virtual Network Adapters

1. Create a Virtual Switch:
> ```powershell
> New-VMSwitch -Name "MainVMSwitch" -NetAdapterName "PhysicalAdapterName" -AllowManagementOS $true
> ```
2. Create Multiple Virtual Network Adapters
> ```powershell
> Add-VMNetworkAdapter -VMName "VM1" -SwitchName "MainVMSwitch" -Name "vNIC1"
> Add-VMNetworkAdapter -VMName "VM2" -SwitchName "MainVMSwitch" -Name "vNIC2"
> ```
3. Configure Virtual Network Adapters: You can assign different VLAN IDs or configure other network settings on these virtual network adapters to isolate traffic as needed.

### Example PowerShell Script for Multiple Virtual Network Adapters

```powershell
# Create the main virtual switch
New-VMSwitch -Name "MainVMSwitch" -NetAdapterName "PhysicalAdapterName" -AllowManagementOS $true

# Create two VMs for the example
New-VM -Name "VM1" -MemoryStartupBytes 2GB -Generation 2 -NewVHDPath "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\VM1.vhdx" -NewVHDSizeBytes 60GB
New-VM -Name "VM2" -MemoryStartupBytes 2GB -Generation 2 -NewVHDPath "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\VM2.vhdx" -NewVHDSizeBytes 60GB

# Add virtual network adapters to each VM
Add-VMNetworkAdapter -VMName "VM1" -SwitchName "MainVMSwitch" -Name "vNIC1"
Add-VMNetworkAdapter -VMName "VM2" -SwitchName "MainVMSwitch" -Name "vNIC2"

# Optionally configure VLAN IDs for each vNIC
Set-VMNetworkAdapterVlan -VMName "VM1" -VMNetworkAdapterName "vNIC1" -Access -VlanId 10
Set-VMNetworkAdapterVlan -VMName "VM2" -VMNetworkAdapterName "vNIC2" -Access -VlanId 20
```