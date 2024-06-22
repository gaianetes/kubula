terraform {
  required_providers {
    hyperv = {
      source  = "taliesins/hyperv"
      version = "1.2.1"
    }
  }
}

provider "hyperv" {
  # Configuration options
  user     = var.admin_username
  password = var.admin_password
  host     = var.host_ip
  port     = 5985
  https    = false
  insecure = true
  #   use_ntlm        = true
  #   tls_server_name = ""
  #   cacert_path     = ""
  #   cert_path       = ""
  #   key_path        = ""
  #   script_path     = "C:/Temp/terraform_%RAND%.cmd"
  timeout = "60s"
}