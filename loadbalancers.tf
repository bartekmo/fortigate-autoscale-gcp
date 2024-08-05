
resource "google_compute_region_health_check" "http8008" {
  name               = "${var.cluster_name}-hc-${random_string.random_name_post.result}"
  region             = var.region
  timeout_sec        = 2
  check_interval_sec = 2

  http_health_check {
    port = 8008
  }
}

# External pass-through network load balancer (group-based)
# 
resource "google_compute_region_backend_service" "elb" {
  name                            = "${var.cluster_name}-elb-${random_string.random_name_post.result}"
  region                          = var.region
  health_checks                   = [google_compute_region_health_check.http8008.id]
  connection_draining_timeout_sec = 10
  load_balancing_scheme           = "EXTERNAL"
  protocol                        = "UNSPECIFIED"

  backend {
    group = google_compute_region_instance_group_manager.fgts.instance_group
  }
}

resource "google_compute_forwarding_rule" "elb" {
  name                  = "${var.cluster_name}-elb-frule-${random_string.random_name_post.result}"
  region                = var.region
  ip_protocol           = "L3_DEFAULT"
  all_ports             = true
  load_balancing_scheme = "EXTERNAL"
  backend_service       = google_compute_region_backend_service.elb.id
}

# Internal network load balancer as dext-hop for default route from protected network
# 
resource "google_compute_region_backend_service" "ilb" {
  name                            = "${var.cluster_name}-ilb-${random_string.random_name_post.result}"
  region                          = var.region
  health_checks                   = [google_compute_region_health_check.http8008.id]
  connection_draining_timeout_sec = 10
  load_balancing_scheme           = "INTERNAL"
  protocol                        = "UNSPECIFIED"
  network                         = google_compute_subnetwork.protected_subnet.network

  backend {
    group = google_compute_region_instance_group_manager.fgts.instance_group
  }
}

resource "google_compute_forwarding_rule" "ilb" {
  name                  = "${var.cluster_name}-ilb-frule-${random_string.random_name_post.result}"
  region                = var.region
  subnetwork            = google_compute_subnetwork.protected_subnet.id
  ip_protocol           = "TCP"
  all_ports             = true
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.ilb.id
  allow_global_access   = true
}

resource "google_compute_route" "default" {
  name         = "${var.cluster_name}-default-via-fgts-${random_string.random_name_post.result}"
  network      = google_compute_subnetwork.protected_subnet.network
  dest_range   = "0.0.0.0/0"
  next_hop_ilb = google_compute_forwarding_rule.ilb.id
}