# provider
provider google {
  project     = var.gcpProjectId
  region      = var.gcpRegion
  zone        = var.gcpZone
}

# project
resource random_pet buildSuffix {
  keepers = {
    prefix = var.projectPrefix
  }
  separator = "-"
}
# networks
# vpc
resource google_compute_network vpc_network_mgmt {
  name                    = "${var.projectPrefix}terraform-network-mgmt-${random_pet.buildSuffix.id}"
  auto_create_subnetworks = "false"
  routing_mode = "REGIONAL"
}
resource google_compute_subnetwork vpc_network_mgmt_sub {
  name          = "${var.projectPrefix}mgmt-sub-${random_pet.buildSuffix.id}"
  ip_cidr_range = "10.0.10.0/24"
  region        = var.gcpRegion
  network       = google_compute_network.vpc_network_mgmt.self_link

}
resource google_compute_network vpc_network_int {
  name                    = "${var.projectPrefix}terraform-network-int-${random_pet.buildSuffix.id}"
  auto_create_subnetworks = "false"
  routing_mode = "REGIONAL"
}
resource google_compute_subnetwork vpc_network_int_sub {
  name          = "${var.projectPrefix}int-sub-${random_pet.buildSuffix.id}"
  ip_cidr_range = "10.0.20.0/24"
  region        = var.gcpRegion
  network       = google_compute_network.vpc_network_int.self_link
}
resource google_compute_network vpc_network_ext {
  name                    = "${var.projectPrefix}terraform-network-ext-${random_pet.buildSuffix.id}"
  auto_create_subnetworks = "false"
  routing_mode = "REGIONAL"
}
resource google_compute_subnetwork vpc_network_ext_sub {
  name          = "${var.projectPrefix}ext-sub-${random_pet.buildSuffix.id}"
  ip_cidr_range = "10.0.30.0/24"
  region        = var.gcpRegion
  network       = google_compute_network.vpc_network_ext.self_link

}
# firewall
resource google_compute_firewall default-allow-internal-mgmt {
  name    = "${var.projectPrefix}default-allow-internal-mgmt-${random_pet.buildSuffix.id}"
  network = google_compute_network.vpc_network_mgmt.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  priority = "65534"

  source_ranges = ["10.0.10.0/24"]
}
resource google_compute_firewall default-allow-internal-ext {
  name    = "${var.projectPrefix}default-allow-internal-ext-${random_pet.buildSuffix.id}"
  network = google_compute_network.vpc_network_ext.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  priority = "65534"

  source_ranges = ["10.0.30.0/24"]
}
resource google_compute_firewall default-allow-internal-int {
  name    = "${var.projectPrefix}default-allow-internal-int-${random_pet.buildSuffix.id}"
  network = google_compute_network.vpc_network_int.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  priority = "65534"

  source_ranges = ["10.0.20.0/24"]
}
resource google_compute_firewall allow-internal-egress {
  name    = "${var.projectPrefix}allow-internal-egress-${random_pet.buildSuffix.id}"
  network = google_compute_network.vpc_network_int.name
  direction = "EGRESS"
  enable_logging = true

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  priority = "65533"

  destination_ranges = ["10.0.20.0/24"]
}
resource google_compute_firewall allow-internal-cis-egress {
  name    = "${var.projectPrefix}allow-internal-cis-egress-${random_pet.buildSuffix.id}"
  network = google_compute_network.vpc_network_int.name
  direction = "EGRESS"
  enable_logging = true

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  priority = "65533"

  destination_ranges = ["10.0.20.0/24"]
}
resource google_compute_firewall allow-internal-cis {
  name    = "${var.projectPrefix}allow-internal-cis-${random_pet.buildSuffix.id}"
  network = google_compute_network.vpc_network_int.name
  enable_logging = true

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  priority = "65532"

  source_ranges = [module.k8s.podCidr]
}
# secret
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = " %*+,-./:=?@[]_~"
}
# k8s
module k8s {
  source   = "./k8s"
  #====================#
  # k8s settings       #
  #====================#
  projectPrefix = var.projectPrefix
  buildSuffix = "-${random_pet.buildSuffix.id}"
  gcpZone = var.gcpZone
  adminAccount      = var.adminAccountName
  adminPass  = var.adminPass != "" ? var.adminPass : random_password.password.result
  int_vpc = google_compute_network.vpc_network_int
  int_subnet = google_compute_subnetwork.vpc_network_int_sub
}

# cis
module cis {
  source   = "./cis"
  #====================#
  # cis settings       #
  #====================#
  gce_ssh_pub_key_file = var.gceSshPubKey
  adminSrcAddr = var.adminSrcAddr
  adminPass = var.adminPass != "" ? var.adminPass : random_password.password.result
  adminAccountName = var.adminAccountName
  mgmt_vpc = google_compute_network.vpc_network_mgmt
  int_vpc = google_compute_network.vpc_network_int
  ext_vpc = google_compute_network.vpc_network_ext
  mgmt_subnet = google_compute_subnetwork.vpc_network_mgmt_sub
  int_subnet = google_compute_subnetwork.vpc_network_int_sub
  ext_subnet = google_compute_subnetwork.vpc_network_ext_sub
  projectPrefix = var.projectPrefix
  projectId = var.gcpProjectId
  service_accounts = var.gcpServiceAccounts
  buildSuffix = "-${random_pet.buildSuffix.id}"
  vm_count = var.instanceCount
  customImage = var.customImage
  bigipLicense1 = var.bigipLicense1
  podCidr = module.k8s.podCidr
  podSubnet = module.k8s.podSubnet
  bigipPodSubnet = cidrsubnet(module.k8s.podCidr,10,199)
}