terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.8.0"
    }
  }
}

locals {
  controller_nodes = flatten([
    for node, amount in var.controllers: [
      for index in range(0, amount): {
        name = node,
        index = index + 1,
        hardware = lookup(var.controller_hardware, node, {})
      }
    ]
  ])

  worker_nodes = flatten([
    for node, amount in var.workers: [
      for index in range(0, amount): {
        name = node,
        index = index + 1
        hardware = lookup(var.worker_hardware, node, {})
      }
    ]
  ])

  k0sctl_controlles = [
    for host in proxmox_vm_qemu.controller :
    {
      role = "controller"
      ssh = {
        address = host.default_ipv4_address
        user = "root"
        port = 22
      }
    }
  ]

  k0sctl_workers = [
    for host in proxmox_vm_qemu.worker :
    {
      role = "worker"
      ssh = {
        address = host.default_ipv4_address
        user = "root"
        port = 22
      }
    }
  ]

  k0sctl_conf = {
    apiVersion = "k0sctl.k0sproject.io/v1beta1"
    kind       = "Cluster"
    metadata = {
      name = var.cluster_name
    }
    spec = {
      hosts = concat(local.k0sctl_controlles, local.k0sctl_workers)
      k0s = {
        version = var.k0s_version
        config = {
          apiVersion = "k0s.k0sproject.io/v1beta1"
          kind       = "Cluster"
          metadata = {
            name = var.cluster_name
          }
          spec = {
            extensions = {
              helm = {
                repositories = var.helm_repositories
                charts       = var.helm_charts
              }
            }
            telemetry = {
              enabled = false
            }
            api = {
              port            = 6443
              k0sApiPort      = 9443
              address         = proxmox_vm_qemu.controller["0"].default_ipv4_address
              sans = [
                for ctrl in proxmox_vm_qemu.controller: ctrl.default_ipv4_address
              ]
            }
            network = {
              podCIDR     = var.pod_cidr
              serviceCIDR = var.svc_cidr
              provider  = "kuberouter"
              calico = null
              kuberouter = {
                mtu = 0
                peerRouterIPs = ""
                peerRouterASNs = ""
                autoMTU = true
              }
              kubeProxy = {
                disabled = false
                mode = "iptables"
              }
            }
            podSecurityPolicy = {
              defaultPolicy = var.pod_sec_policy
            }
            konnectivity = {
              agentPort = 8132
              adminPort = 8133
            }
            images = {
              konnectivity = {
                image   = "us.gcr.io/k8s-artifacts-prod/kas-network-proxy/proxy-agent"
                version = var.konnectivity_version
              }
              metricsserver = {
                image   = "gcr.io/k8s-staging-metrics-server/metrics-server"
                version = var.metrics_server_version
              }
              kubeproxy = {
                image   = "k8s.gcr.io/kube-proxy"
                version = var.kube_proxy_version
              }
              coredns = {
                image   = "docker.io/coredns/coredns"
                version = var.core_dns_version
              }
              calico = {
                cni = {
                  image   = "calico/cni"
                  version = var.calico_version
                }
                node = {
                  image =  "docker.io/calico/node"
                  version: var.calico_node_version
                }
                kubecontrollers = {
                  image: "docker.io/calico/kube-controllers"
                  version: var.kube_controllers_version
                }
              }
              kuberouter = {
                cni = {
                  image: "docker.io/cloudnativelabs/kube-router"
                  version: var.kube_router_version
                }
                cniInstaller = {
                  image: "quay.io/k0sproject/cni-node"
                  version: var.cni_node_version
                }
              }
              default_pull_policy = "IfNotPresent"
            }
          }
        }
      }
    }
  }
  config_sha256sum = sha256(tostring(jsonencode(local.k0sctl_conf)))
  controller_sha256sum = sha256(tostring(jsonencode(local.controller_nodes)))
  worker_sha256sum = sha256(tostring(jsonencode(local.worker_nodes)))
}

resource "proxmox_vm_qemu" "controller" {
  for_each = {
    for node in local.controller_nodes : index(local.controller_nodes, node) => node
  }
  name = "controller-${each.key}.${var.cluster_name}"
  target_node = each.value.name
  clone = var.template

  vcpus = lookup(each.value.hardware, "vcpus", 1)
  memory = lookup(each.value.hardware, "memory", 1024)

  os_type = "cloud-init"
  ipconfig0 = var.ipconfig

  ciuser = "root"
  sshkeys = var.ssh_keys

  disk {
    type = "scsi"
    size = lookup(each.value.hardware, "disk_size", "4G")
    storage = lookup(each.value.hardware, "storage", "local-lvm")
  }

  network {
    model = "virtio"
    bridge = lookup(each.value.hardware, "bridge", "vmbr0")
    tag = var.vlan
  }

  vmid = lookup(each.value.hardware, "vmid", 0) != 0 ? lookup(each.value.hardware, "vmid", 0) + each.key : 0

  # Issue - https://github.com/Telmate/terraform-provider-proxmox/issues/282
  boot = "order=scsi0;ide2;net0"
  # Issue - https://github.com/Telmate/terraform-provider-proxmox/issues/325
  agent = 1
}

resource "proxmox_vm_qemu" "worker" {
  for_each = {
    for node in local.worker_nodes : index(local.worker_nodes, node) => node
  }

  name = "worker-${each.key}.${var.cluster_name}"
  target_node = each.value.name
  clone = var.template

  os_type = "cloud-init"
  ipconfig0 = var.ipconfig

  ciuser = "root"
  sshkeys = var.ssh_keys

  vcpus = lookup(each.value.hardware, "vcpus", 1)
  memory = lookup(each.value.hardware, "memory", 2048)

  disk {
    type = "scsi"
    size = lookup(each.value.hardware, "disk_size", "8G")
    storage = lookup(each.value.hardware, "storage", "local-lvm")
  }

  network {
    model = "virtio"
    bridge = lookup(each.value.hardware, "bridge", "vmbr0")
    tag = var.vlan
  }

  vmid = lookup(each.value.hardware, "vmid", 0) != 0 ? lookup(each.value.hardware, "vmid", 0) + each.key : 0

  # Issue - https://github.com/Telmate/terraform-provider-proxmox/issues/282
  boot = "order=scsi0;ide2;net0"
  # Issue - https://github.com/Telmate/terraform-provider-proxmox/issues/325
  agent = 1
}

# K0S
resource "null_resource" "k0s" {
  depends_on = [
    proxmox_vm_qemu.controller,
    proxmox_vm_qemu.worker
  ]

  triggers = {
    controllers = local.controller_sha256sum
    workers     = local.worker_sha256sum
    config      = local.config_sha256sum
  }

  provisioner "local-exec" {
    command = <<-EOT
      cat <<-EOF > k0sctl.yaml
      ${yamlencode(local.k0sctl_conf)}
      EOF
      k0sctl apply

EOT
  }
}

resource "null_resource" "kubeconfig" {
  depends_on = [
    null_resource.k0s
  ]

  triggers = {
    cluster = null_resource.k0s.id
  }

  count = var.write_kubeconfig ? 1 : 0

  provisioner "local-exec" {
    command = "k0sctl kubeconfig > admin.conf"
  }
}
