# module "test_log_configuration" {
#   source = "../"
#
#   name = "configuration_test"
#   image = "log_configuration_test"
#   logging_driver = "awslogs"
#   logging_options = {
#     foo = "Bar"
#   }
# }
#
# output "test_log_configuration" {
#   value = module.test_log_configuration.json
# }
