variable "host_ip" {
  description = "The IP address of the hyper-v host"
  type        = string
}

variable "memory" {
  description = "The amount of memory to allocate to the hyper-v machine in MB"
  type        = number
  default     = 2048
}

variable "processor_count" {
  description = "The number of processors to allocate to the hyper-v machine"
  type        = number
  default     = 2
}

variable "disk_size" {
  description = "The size of the disk to allocate to the hyper-v machine in GB"
  type        = number
  default     = 20
}

variable "network_switch_name" {
  description = "The name of the network switch to connect the hyper-v machine to"
  type        = string
  default     = "VSwitch"
}

variable "admin_password" {
  description = "The password for the administrator account on the hyper-v machine"
  type        = string
}

variable "admin_username" {
  description = "The username for the administrator account on the hyper-v machine"
  type        = string
  default     = "Administrator"
}

variable "vm_name" {
  description = "The name of the hyper-v machine"
  type        = string
  default     = "smigula-cluster1-cp"
}

variable "generation" {
  description = "The generation of the hyper-v machine"
  type        = number
  default     = 1
}

variable "notes" {
  description = "The notes to add to the hyper-v machine"
  type        = string
  default     = "Created by Terraform"
}

variable "smart_paging_file_pathsmart_paging_file_path" {
  description = "The path to the smart paging file"
  type        = string
  default     = "C:\\ProgramData\\Microsoft\\Windows\\Hyper-V"
}

variable "snapshot_file_location" {
  description = "The location to store the snapshots"
  type        = string
  default     = "C:\\ProgramData\\Microsoft\\Windows\\Hyper-V"
}

variable "enable_secure_boot" {
  description = "Enable secure boot"
  type        = string
  default     = "Off"
}

variable "console_mode" {
  description = "The console mode"
  type        = string
  default     = "Default"
}

variable "pause_after_boot_failure" {
  description = "Pause after boot failure"
  type        = string
  default     = "Off"
}

variable "boot_order_path" {
  description = "The path to the boot order"
  type        = string
  default     = "D:\\Shares\\SMGSHR01\\rocky-9-base.vhdx"
  # default     = "/mnt/smigula/rocky-9-base.vhdx"
}

variable "vhd_path" {
  description = "The path to the VHD file"
  type        = string
  default     = "D:\\Shares\\SMGSHR01\\rocky-9-base.vhdx"
  # default     = "/mnt/smigula/rocky-9-base.vhdx"
}

variable "port_mirroring" {
  description = "Enable port mirroring"
  type        = string
  default     = "Off"
}

variable "wait_for_ips" {
  description = "Wait for IPs"
  type        = bool
  default     = true
}

variable "static_ip" {
  description = "The static IP address to assign to the hyper-v machine"
  type        = string
  default     = "192.168.1.101"
}

variable "subnet_mask" {
  description = "The subnet mask to assign to the hyper-v machine"
  type        = string
  default     = "255.255.255.0"
}

variable "gateway_ip" {
  description = "The gateway IP address to assign to the hyper-v machine"
  type        = string
  default     = "192.168.1.1"
}

variable "dns_server" {
  description = "The DNS server IP address to assign to the hyper-v machine"
  type        = string
  default     = "192.168.1.6"
}

variable "enable_vswitch_create" {
  description = "Enable vswitch create"
  type        = bool
  default     = false
}

variable "enable_machine_create" {
  description = "Enable hyperv machine create"
  type        = bool
  default     = true
}