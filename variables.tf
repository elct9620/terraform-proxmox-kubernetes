variable "cluster_name" {
  description = "The cluster name"
  type = string
  default = "kubernetes"
}

variable "template" {
  description = "The template to clone"
  type = string
  default = "Ubuntu-20.04"
}

variable "controllers" {
  description = "The controller panel count"
  type        = map
  default     = { "primary" = 1 }
}

variable "workers" {
  description = "The worker count"
  type        = map
  default     = { "primary" = 3 }
}

variable "ssh_keys" {
  description = "The SSH keys to install into virtual machine"
  type = string
  default = ""
}

variable "ipconfig" {
  description = "The ipconfig optoins to cloud-init"
  type = string
  default = "ip=10.0.0.0/16"
}

variable "vlan" {
  description = "The VLAN tag for virtual machines"
  type = number
  default = -1
}

variable "controller_hardware" {
  description = "The hardware config for controller"
  type = map(map(any))
  default = {}
}

variable "worker_hardware" {
  description = "The hardware config for worker"
  type = map(map(any))
  default = {}
}

variable "write_kubeconfig" {
  description = "Write Kubeconfig locally."
  type        = bool
  default     = true
}

# Pod
variable "pod_cidr" {
  description = "Pod CIDR Subnet."
  type        = string
  default     = "10.244.0.0/16"
}

variable "svc_cidr" {
  description = "Cluster Service CIDR subnet."
  type        = string
  default     = "10.96.0.0/12"
}

variable "pod_sec_policy" {
  description = "K0s Pod Security Policy."
  type        = string
  default     = "00-k0s-privileged"
}

# Versions
variable "k0s_version" {
  description = "K0s Configuration K0s version."
  type        = string
  default     = "v1.22.2+k0s.0"
}

variable "konnectivity_version" {
  description = "K0s Configuration Konnectivity Version."
  type        = string
  default     = "v0.0.24"
}

variable "metrics_server_version" {
  description = "K0s Configuration Kube Metrics Version."
  type        = string
  default     = "v0.5.0"
}

variable "kube_proxy_version" {
  description = "K0s Configuration Kube Proxy version."
  type        = string
  default     = "v1.22.2"
}

variable "core_dns_version" {
  description = "K0s Configuration CoreDNS version."
  type        = string
  default     = "1.7.0"
}

variable "calico_version" {
  description = "K0s Configuration Calico version."
  type        = string
  default     = "v3.18.1"
}

variable "calico_node_version" {
  description = "K0s Configuration Calico Node version."
  type        = string
  default     = "v3.18.1"
}

variable "kube_controllers_version" {
  description = "K0s Configuration Kube Controllers version."
  type        = string
  default     = "v3.18.1"
}

variable "kube_router_version" {
  description = "K0s Configuration Kube Router version."
  type        = string
  default     = "v1.2.1"
}

variable "cni_node_version" {
  description = "K0s Configuration CNI Installer version."
  type        = string
  default     = "0.1.0"
}

# Helm Extension
variable "helm_repositories" {
  type    = list(map(any))
  default = []
}

variable "helm_charts" {
  type    = list(map(any))
  default = []
}
