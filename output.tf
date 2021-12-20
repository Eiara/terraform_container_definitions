output "map" {
  value = local.output
}

# output "json" {
#   value = "${data.template_file._final.rendered}"
# }

output "name" {
  value = var.name
}
