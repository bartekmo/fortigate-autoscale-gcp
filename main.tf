
provider "google" {
  credentials = fileexists(var.auth_key) ? file(var.auth_key) : null
  project     = var.project
  region      = var.region
  zone        = var.zone
}
provider "google-beta" {
  credentials = fileexists(var.auth_key) ? file(var.auth_key) : null
  project     = var.project
  region      = var.region
  zone        = var.zone
}

resource "random_string" "psk" {
  length           = 16
  special          = true
  override_special = "![]{}"
}
#Random 5 char string appended to the end of each name to avoid conflicts
resource "random_string" "random_name_post" {
  length           = 5
  special          = true
  override_special = ""
  min_lower        = 5
}