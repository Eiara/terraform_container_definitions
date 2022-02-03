module "test_command" {
  source = "../"

  name = "command_test"
  image = "command_test"
  command = ["a","b","c"]
}

output "test_command" {
  value = jsonencode(module.test_command.map)
}
