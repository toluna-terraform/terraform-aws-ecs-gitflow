data "consul_keys" "current_color" {
  key {
    name    = "current_color"
    path    = "infra/chef-srinivas/current_color"
  }
}