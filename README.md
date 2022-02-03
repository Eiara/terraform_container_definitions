# Terraform Container Definitions

Terraform natively supports AWS Elastic Container Service task definitions, but doesn't make it easy to make container definitions that go into task definitions, and currently recommends loading container definitions from on-disk templates.

This module is intended to provide a standard interface for Terraform, to dynamically generate an appropriate map data structure, including appropriate data validation, to ensure easier ECS usage.

This exists because correctly generating ECS configuration maps is often Hard, and having Terraform raise an error with your configuration before ECS sees it is often very useful.

## Usage
```hcl

    variable "container_name" {
      default = "hello_world"
    }

    module "hello_world" {
        source                = "github.com/eiara/terraform_container_definitions"

        name                  = var.container_name
        image                 = "hello-world"
        essential             = true
        memory                = 25
        cpu                   = 10
        environment = {
          VAR_1               = "hello"
          VAR_2               = "world"
        }
    }

    resource "aws_ecs_task_definition" "hello_world" {
        family                = "hello_world"
        container_definitions = jsonencode(module.hello_world.map)
    }

    data "aws_ecs_task_definition" "hello_world" {
      task_definition = aws_ecs_task_definition.hello_world.family
    }

    data "aws_ecs_container_definition" "hello_world" {
      task_definition = data.aws_ecs_task_definition.hello_world.id
      name            = var.container_name
    }

    output "container_image" {
      value = data.aws_ecs_container_definition.hello_world.image # "hello-world"
    }
```

## Supported Parameters

Currently this module does not support the entirety of [full range of AWS container definition options](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definitions)

The list of supported parameters is

  - `name` (string)
  - `image` (string)
  - `cpu` (number)
  - `memory` (number)
  - `essential` (boolean)
  - `links` (list)
  - `port_mappings` (list of maps)
  - `environment` (map)
  - `mount_points` (list of maps)
  - `volumes_from` (list of maps)

Assume that all parameter names that would normally be _camelCase_ have been changed to use underscores. For example, `volumesFrom` moves to `volumes_from`, and `sourceContainer` to `source_container`, and so on, to match Terraform's style.

## Legacy

If you were using the previous string-composition version of this repository, it can be found at github.com/eiara/terraform_container_definitions?ref=v0.9`

# License

This project is copyright 2017 Eiara Limited, and licensed under the terms of the MIT license.
