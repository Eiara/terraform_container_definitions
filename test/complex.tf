module "ecs_app" {
  source = "../"

  name      = "test"
  image     = "hello:there"
  essential = true
  memory    = 25
  cpu       = 10

  port_mappings = [
    {
      container_port = 80
      host_port      = 80
    },
  ]

  environment = {
    HTTP_PORT = 80
  }
}

output "test_ecs_app" {
  value = jsonencode(module.ecs_app.map)
}
