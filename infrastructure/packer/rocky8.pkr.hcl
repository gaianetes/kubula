packer {
  required_plugins {
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
    virtualbox = {
      source  = "github.com/hashicorp/virtualbox"
      version = "~> 1"
    }
  }
}

variable "boot_wait" {
  type    = string
  default = "5s"
}

variable "disk_size" {
  type    = string
  default = "51200"
}

variable "iso_checksum" {
  type    = string
  default = "88baefca6f0e78b53613773954e0d7c2d8d28ad863f40623db75c40f505b5105"
}

variable "iso_url" {
  type    = string
  default = "https://download.rockylinux.org/pub/rocky/8/isos/x86_64/Rocky-8.9-x86_64-boot.iso"
}

variable "memsize" {
  type    = string
  default = "4096"
}

variable "numvcpus" {
  type    = string
  default = "2"
}

variable "ssh_password" {
  type    = string
  default = "packer"
}

variable "ssh_username" {
  type    = string
  default = "packer"
}

variable "vm_name" {
  type    = string
  default = "Rocky-8.9-x86_64"
}

variable "version" {
  type    = string
  default = "0.1.0"
}

variable "vagrant_cloud_token" {
  type = string
  sensitive = true
}

source "virtualbox-iso" "rocky" {
  boot_command         = ["<tab><bs><bs><bs><bs><bs>text ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter><wait>"]
  boot_wait            = "${var.boot_wait}"
  disk_size            = "${var.disk_size}"
  guest_additions_mode = "disable"
  guest_os_type        = "RedHat_64"
  headless             = false
  http_directory       = "./http"
  iso_checksum         = "${var.iso_checksum}"
  iso_url              = "${var.iso_url}"
  shutdown_command     = "echo 'packer'|sudo -S /sbin/halt -h -p"
  ssh_password         = "${var.ssh_password}"
  ssh_port             = 22
  ssh_timeout          = "30m"
  ssh_username         = "${var.ssh_username}"
  vboxmanage = [
    ["modifyvm", "{{ .Name }}", "--memory", "${var.memsize}"],
    ["modifyvm", "{{ .Name }}", "--cpus", "${var.numvcpus}"],
    ["modifyvm", "{{ .Name }}", "--nat-localhostreachable1", "on"]
  ]
  vm_name = "${var.vm_name}"
}

build {
  sources = ["source.virtualbox-iso.rocky"]

  provisioner "shell" {
    execute_command = "echo 'packer'|{{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    inline          = ["dnf -y update", "dnf -y install python3", "alternatives --set python /usr/bin/python3", "python3 -m pip install -U pip", "pip3 install ansible"]
  }

  provisioner "ansible-local" {
    playbook_file = "ansible/main.yaml"
  }

  # provisioner "shell" {
  #   execute_command = "echo 'packer'|{{ .Vars }} sudo -S -E bash '{{ .Path }}'"
  #   scripts         = ["scripts/setup.sh"]
  # }

  post-processors {
    post-processor "vagrant" {
      output = "builds/{{ .Provider }}-rockylinux8.box"
    }
    post-processor "vagrant-cloud" {
      box_tag = "mitchmurphy/rockylinux-rke2"
      version = "${var.version}"
      access_token = "${var.vagrant_cloud_token}"
      keep_input_artifact = true
    }
  }

}