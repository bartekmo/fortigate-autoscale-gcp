
# External pass-through network load balancer (group-based)
# 
resource "google_compute_region_health_check" "elb" {
  name               = "${var.cluster_name}-hc-${random_string.random_name_post.result}"
  region             = var.region
  timeout_sec        = 2
  check_interval_sec = 2

  http_health_check {
    port = 8008
  }
}

resource "google_compute_region_backend_service" "elb" {
  name                            = "${var.cluster_name}-elb-${random_string.random_name_post.result}"
  region                          = var.region
  health_checks                   = [google_compute_region_health_check.elb.id]
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