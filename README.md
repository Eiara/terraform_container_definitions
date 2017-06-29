# Terraform Container Definitions

Terraform natively supports AWS Elastic Container Service task definitions, but doesn't make it easy to make container definitions that go into task definitions, and currently recommends loading container definitions from on-disk templates.

This module is intended to provide a standard module interface for Terraform, to dynamically generate the JSON blobs needed for container definitions.

This exists because Terraform is not (as of v0.9.9) able to use `jsonencode()` on nested maps or lists, only flat maps and lists.

## Usage
```
    
    variable "container_name" {
      default = "hello_world"
    }
    
    module "hello_world_" {
        source                = "github.com/eiara/terraform_container_definitions"
                              
        name                  = "${var.container_name}"
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
        container_definitions = "${module.hello_world.json}"
    }
    
    data "aws_ecs_task_definition" "hello_world" {
      task_definition = "${aws_ecs_task_definition.hello_world.family}"
    }
    
    data "aws_ecs_container_definition" "hello_world" {
      task_definition = "${data.aws_ecs_task_definition.hello_world.id}"
      name            = "${var.container_name}"
    }
    
    output "container_image" {
      value = "${data.aws_ecs_container_definition.hello_world.image}" # "hello-world"
    }
```

## Supported Parameters

Currently this module does not support the entirety of [full range of AWS container definition options](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definitions)

The list of supported parameters is

  - name (string)
  - image (string)
  - cpu (number)
  - memory (number)
  - essential (boolean)
  - links (list)
  - port_mappings (list of maps)
  - environment (map)
  - mount_points (list of maps)
  - volumes_from (list of maps)

Assume that all parameter names that would normally be _camelCase_ have been changed to use underscores. For example, `volumesFrom` moves to `volumes_from`, and `sourceContainer` to `source_container`, and so on, to match Terraform's style.

# License

This project is copyright 2017 Eiara Limited, and licensed under the terms of the MIT license.