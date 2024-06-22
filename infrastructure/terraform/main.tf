locals {
  memory_in_bytes    = var.memory * 1024 * 1024           # convert MB to bytes
  disk_size_in_bytes = var.disk_size * 1024 * 1024 * 1024 # convert GB to bytes
}


# create a Virtual Switch
resource "hyperv_network_switch" "default" {
  count                                   = var.enable_vswitch_create ? 1 : 0
  name                                    = "extSwitch"
  notes                                   = "Test creating switch via Terraform"
  allow_management_os                     = true
  enable_embedded_teaming                 = false
  enable_iov                              = false
  enable_packet_direct                    = false
  minimum_bandwidth_mode                  = "None"
  switch_type                             = "External"
  net_adapter_names                       = ["Ethernet"] # Run this command in powershell to get the adapter names: Get-NetAdapter | Select-Object Name
  default_flow_minimum_bandwidth_absolute = 0
  default_flow_minimum_bandwidth_weight   = 0
  default_queue_vmmq_enabled              = false
  default_queue_vmmq_queue_pairs          = 16
  default_queue_vrss_enabled              = false
}


# create a hyper-v machine
resource "hyperv_machine_instance" "default" {
  count                                   = var.enable_machine_create ? 1 : 0
  name                                    = var.vm_name
  generation                              = var.generation
  automatic_critical_error_action         = "Pause" # Valid values to use are Pause, None
  automatic_critical_error_action_timeout = 30
  automatic_start_action                  = "StartIfRunning" # Valid values to use are Nothing, StartIfRunning, Start
  automatic_start_delay                   = 0
  automatic_stop_action                   = "Save"     # Valid values to use are TurnOff, Save, ShutDown
  checkpoint_type                         = "Standard" # Valid values to use are Disabled, Standard, Production, ProductionOnly
  guest_controlled_cache_types            = false
  high_memory_mapped_io_space             = local.memory_in_bytes
  lock_on_disconnect                      = "Off"
  low_memory_mapped_io_space              = local.memory_in_bytes
  # Applies only to virtual machines using dynamic memory
  memory_maximum_bytes   = local.memory_in_bytes
  memory_minimum_bytes   = local.memory_in_bytes
  memory_startup_bytes   = local.memory_in_bytes
  notes                  = var.notes
  processor_count        = var.processor_count
  smart_paging_file_path = var.smart_paging_file_pathsmart_paging_file_path
  snapshot_file_location = var.snapshot_file_location
  #   dynamic_memory                         = false
  static_memory = true
  state         = "Running" # Valid values to use are Running, Off

  # Configure firmware
  vm_firmware {
    enable_secure_boot = var.enable_secure_boot
    #secure_boot_template            = ""
    # preferred_network_boot_protocol = "IPv4" # Valid values to use are IPv4, IPv6
    console_mode             = var.console_mode             # Valid values to use are Default, COM1, COM2, None
    pause_after_boot_failure = var.pause_after_boot_failure # Valid values to use are On, Off
    boot_order {
      boot_type = "HardDiskDrive" # Valid values to use are NetworkAdapter, HardDiskDrive and DvdDrive
    }
  }

  # Configure processor
  vm_processor {
    compatibility_for_migration_enabled               = false
    compatibility_for_older_operating_systems_enabled = false
    hw_thread_count_per_core                          = 0
    maximum                                           = 100
    reserve                                           = 0
    relative_weight                                   = 100
    maximum_count_per_numa_node                       = 0
    maximum_count_per_numa_socket                     = 0
    enable_host_resource_protection                   = false
    expose_virtualization_extensions                  = false
  }

  # Configure integration services
  integration_services = {
    "Guest Service Interface" = false
    "Heartbeat"               = true
    "Key-Value Pair Exchange" = true
    "Shutdown"                = true
    "Time Synchronization"    = true
    "VSS"                     = true
  }

  # Create a network adaptor
  network_adaptors {
    name        = "wan"
    switch_name = var.network_switch_name
  }

  # Create a hard disk drive
  hard_disk_drives {
    controller_type     = "Ide"
    controller_number   = "0"
    controller_location = "0"
    path                = var.vhd_path
  }

  # this currently does not work. Need to figure out how to set the IP address of the machine...
  provisioner "local-exec" {
    command = <<-EOT
      powershell -NoProfile -ExecutionPolicy Bypass -Command "& {
        \$vmName = '${var.vm_name}'
        \$ipAddress = '${var.static_ip}'
        \$subnetMask = '${var.subnet_mask}'
        \$gateway = '${var.gateway_ip}'
        \$dnsServer = '${var.dns_server}'

        \$vm = Get-VM -Name \$vmName
        if (\$vm -ne \$null) {
          \$adapter = Get-VMNetworkAdapter -VMName \$vmName
          if (\$adapter -ne \$null) {
            \$adapter | Set-VMNetworkAdapter -StaticMacAddress '00-15-5D-01-01-01'
            New-NetIPAddress -IPAddress \$ipAddress -PrefixLength 24 -InterfaceIndex \$adapter.InterfaceIndex
            Set-DnsClientServerAddress -InterfaceIndex \$adapter.InterfaceIndex -ServerAddresses \$dnsServer
            New-NetRoute -DestinationPrefix '0.0.0.0/0' -NextHop \$gateway -InterfaceIndex \$adapter.InterfaceIndex
          }
        }
      }"
    EOT
  }
}