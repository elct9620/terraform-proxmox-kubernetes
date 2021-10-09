Terraform ProxmoxVE Kuberentes
===

This project is inspired by [vultr/condor](https://github.com/vultr/terraform-vultr-condor) but design for ProxmoxVE.

## Requirements

1. Configure [ProxmoxVE Provider](https://github.com/Telmate/terraform-provider-proxmox) before use this module.
2. Ensure `Pool.Allocate` and `Sys.Modify` is added to Token permission which document not noted.
3. Prepare a cloud-init template with Qemu Guest Agent

## Usage

The exampe config use this module

```tf
module "pkube" {
  source  = "elct9620/kuberentes/proxmox"
  version = "0.1.0"

  cluster_name = "example"
  ipconfig = "ip=dhcp"
  # vlan = 1

  ssh_keys = <<EOF
[YOUR_KEYS]
  EOF


  controllers = { "primary" = 1 }
  controller_hardware = {
    "primary" = {
      "vmid" = 5000, # VMID start with 5000
      "vcpus" = 1,
      "memory" = 2048,
      "disk_size" = "8G",
      "storage" = "local-lvm",
    }
  }

  workers = { "primary" = 3 }
  worker_hardware = {
    "pve-primary" = {
      vmid = 5100, # VMID start with 5100
      vcpus = 1,
      memory = 2048,
      disk_size = "32G",
      storage = "local-lvm",
    }
  }

  helm_repositories = [
    # ...
  ]

  helm_charts = [
    # ...
  ]
}
```
