module "test" {
  source = "../"
  
  name = "command_test"
  image = "command_test"
  command = ["a","b","c"]
}

output "test" {
  value = "${module.test.json}"
}