# output the ip address of the machine
output "ip_address" {
  value = var.enable_machine_create ? hyperv_machine_instance.default.network_adaptors[*].ip_addresses : null
}


# output virtual switch
output "virtual_switch" {
  value = var.enable_vswitch_create ? hyperv_virtual_switch.default.name : null
}