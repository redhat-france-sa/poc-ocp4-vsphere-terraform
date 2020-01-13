provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "${var.vsphere_datacenter}"
}

module "folder" {
  source = "./folder"

  path          = "${var.cluster_id}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

module "resource_pool" {
  source = "./resource_pool"

  name            = "${var.cluster_id}"
  datacenter_id   = "${data.vsphere_datacenter.dc.id}"
  vsphere_cluster = "${var.vsphere_cluster}"
}

module "bootstrap" {
  source = "./machine"

  name             = "bootstrap"
  // instance_count   = "${var.bootstrap_complete ? 0 : 1}"
  instance_count   = "1"
  ignition_url     = "${var.bootstrap_ignition_url}"
  resource_pool_id = "${module.resource_pool.pool_id}"
  datastore        = "${var.vsphere_datastore}"
  folder           = "${module.folder.path}"
  network          = "${var.vm_network}"
  datacenter_id    = "${data.vsphere_datacenter.dc.id}"
  template         = "${var.vm_template}"
  cluster_domain   = "${var.cluster_domain}"
  ipam             = "${var.ipam}"
  ipam_token       = "${var.ipam_token}"
  // ip_addresses     = ["${compact(list(var.bootstrap_ip))}"]
  ip_addresses     = ["10.126.72.208"]
  mac_addresses    = ["00:50:56:a5:c4:d7"]
  machine_cidr     = "${var.machine_cidr}"
  memory           = "8192"
  num_cpu          = "4"
}

module "control_plane" {
  source = "./machine"

  name             = "control-plane"
  instance_count   = "${var.control_plane_count}"
  ignition         = "${var.control_plane_ignition}"
  resource_pool_id = "${module.resource_pool.pool_id}"
  folder           = "${module.folder.path}"
  datastore        = "${var.vsphere_datastore}"
  network          = "${var.vm_network}"
  datacenter_id    = "${data.vsphere_datacenter.dc.id}"
  template         = "${var.vm_template}"
  cluster_domain   = "${var.cluster_domain}"
  ipam             = "${var.ipam}"
  ipam_token       = "${var.ipam_token}"
  ip_addresses     = ["${var.control_plane_ips}"]
  mac_addresses    = var.control_plane_macs
  machine_cidr     = "${var.machine_cidr}"
  memory           = "16384"
  num_cpu          = "4"
}

module "compute" {
  source = "./machine"

  name             = "compute"
  instance_count   = "${var.compute_count}"
  ignition         = "${var.compute_ignition}"
  resource_pool_id = "${module.resource_pool.pool_id}"
  folder           = "${module.folder.path}"
  datastore        = "${var.vsphere_datastore}"
  network          = "${var.vm_network}"
  datacenter_id    = "${data.vsphere_datacenter.dc.id}"
  template         = "${var.vm_template}"
  cluster_domain   = "${var.cluster_domain}"
  ipam             = "${var.ipam}"
  ipam_token       = "${var.ipam_token}"
  ip_addresses     = ["${var.compute_ips}"]
  mac_addresses    = var.compute_macs
  machine_cidr     = "${var.machine_cidr}"
  memory           = "8192"
  num_cpu          = "4"
}

// module "dns" {
//   source = "./route53"
// 
//   base_domain         = "${var.base_domain}"
//   cluster_domain      = "${var.cluster_domain}"
//   bootstrap_count     = "${var.bootstrap_complete ? 0 : 1}"
//   bootstrap_ips       = ["${module.bootstrap.ip_addresses}"]
//   control_plane_count = "${var.control_plane_count}"
//   control_plane_ips   = ["${module.control_plane.ip_addresses}"]
//   compute_count       = "${var.compute_count}"
//   compute_ips         = ["${module.compute.ip_addresses}"]
// }
