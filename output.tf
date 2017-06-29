output "json" {
  value = "${data.template_file._final.rendered}"
}