output "current_color" {
    value = data.consul_keys.current_color.var.current_color
    sensitive = true
}