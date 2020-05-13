# __author__ = "Alejandro Guadarrama Dominguez"
# __copyright__ = "Copyright 2020, Alejandro Guadarrama Dominguez"
# __credits__ = ["Alejandro Guadarrama Dominguez"]
# __license__ = "GPL"
# __version__ = "0.0.1"
# __maintainer__ = "Alejandro Guadarrama Dominguez"
# __email__ = "alexgd.devops@gmail.com"
# __status__ = "Dev"

#  Deploy ocp4 infrastructure to vmware

variable vsphere_user {}
variable vsphere_password {}
variable vsphere_server {}
variable ocp_cluster_name {}
variable full_path {}
variable virtual_machines {}
variable datacenter {}
variable datastore {}
variable cluster {}
variable network {}
variable resource_pool {}
variable host {}
variable template {}
variable node_network {}
variable node_configs {}

provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "sni" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_folder" "cluster" {
  path          = var.ocp_cluster_name
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "sni" {
  name          = var.resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_host" "esxi67" {
  name          = var.host
  datacenter_id = data.vsphere_datacenter.dc.id
}

module "template" {
  source           = "./modules/create_template"
  name             = var.template.name
  local_ovf        = "${path.module}/${var.template.ovf_name}"
  resource_pool_id = data.vsphere_resource_pool.sni.id
  host             = var.host
  datastore        = var.datastore
  datacenter       = var.datacenter
  folder           = vsphere_folder.cluster.path
}

module "create_ignitions" {
  source = "./modules/create_ignitions"

}

module "bootstrap" {
  source           = "./modules/clone_from_template"
  folder           = vsphere_folder.cluster.path
  resource_pool_id = data.vsphere_resource_pool.sni.id
  host_system_id   = data.vsphere_host.esxi67.id
  datastore_id     = data.vsphere_datastore.datastore.id
  network_id       = data.vsphere_network.network.id
  guest_id         = module.template.guest_id
  adapter_type     = module.template.adapter_type[0].adapter_type
  template_uuid    = module.template.template_id
  vm_data          = var.virtual_machines.bootstrap
  node_network     = var.node_network
  cluster_name     = var.ocp_cluster_name
  node_config      = var.node_configs.bootstrap
}

module "master" {
  source           = "./modules/clone_from_template"
  folder           = vsphere_folder.cluster.path
  resource_pool_id = data.vsphere_resource_pool.sni.id
  host_system_id   = data.vsphere_host.esxi67.id
  datastore_id     = data.vsphere_datastore.datastore.id
  network_id       = data.vsphere_network.network.id
  guest_id         = module.template.guest_id
  adapter_type     = module.template.adapter_type[0].adapter_type
  template_uuid    = module.template.template_id
  vm_data          = var.virtual_machines.master
}

module "worker" {
  source           = "./modules/clone_from_template"
  folder           = vsphere_folder.cluster.path
  resource_pool_id = data.vsphere_resource_pool.sni.id
  host_system_id   = data.vsphere_host.esxi67.id
  datastore_id     = data.vsphere_datastore.datastore.id
  network_id       = data.vsphere_network.network.id
  guest_id         = module.template.guest_id
  adapter_type     = module.template.adapter_type[0].adapter_type
  template_uuid    = module.template.template_id
  vm_data          = var.virtual_machines.worker
}

module "infra" {
  source           = "./modules/clone_from_template"
  folder           = vsphere_folder.cluster.path
  resource_pool_id = data.vsphere_resource_pool.sni.id
  host_system_id   = data.vsphere_host.esxi67.id
  datastore_id     = data.vsphere_datastore.datastore.id
  network_id       = data.vsphere_network.network.id
  guest_id         = module.template.guest_id
  adapter_type     = module.template.adapter_type[0].adapter_type
  template_uuid    = module.template.template_id
  vm_data          = var.virtual_machines.infra
}

module "logging" {
  source           = "./modules/clone_from_template"
  folder           = vsphere_folder.cluster.path
  resource_pool_id = data.vsphere_resource_pool.sni.id
  host_system_id   = data.vsphere_host.esxi67.id
  datastore_id     = data.vsphere_datastore.datastore.id
  network_id       = data.vsphere_network.network.id
  guest_id         = module.template.guest_id
  adapter_type     = module.template.adapter_type[0].adapter_type
  template_uuid    = module.template.template_id
  vm_data          = var.virtual_machines.logging
}

output machine {
  value = module.template.machine
}
