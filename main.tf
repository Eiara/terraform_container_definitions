# This is done because boolean values cross the module boundary as 0 and 1,
# So we need to cheaply cast it back to the literal of `false` and `true`

data "template_file" "essential" {
  template = "$${jsonencode("essential")}: $${val ? true : false}"

  vars {
    val = "${var.essential != "" ? var.essential : "false"}"
  }
}

# Set up the port mappings
# Done in this way because Terraform is "helpful" when it comes to rendering
# numbers via jsonencode, and treats them as strings, which fails the struct
# validation later

data "template_file" "_port_mapping" {
  count = "${length(var.port_mappings)}"

  template = <<JSON
{$${join(",",
  compact(
    list(
    hostPort == "" ? "" : "$${jsonencode("hostPort")}: $${hostPort}",
    "$${jsonencode("containerPort")}: $${containerPort}",
    protocol == "" ? "" : "$${jsonencode("protocol")}: $${jsonencode(protocol)}"
    )
  )
)}}
JSON

  vars {
    hostPort = "${ lookup(var.port_mappings[count.index], "host_port", "") }"

    # So that TF will throw an error - this is a required field
    containerPort = "${ lookup(var.port_mappings[count.index], "container_port") }"
    protocol      = "${ lookup(var.port_mappings[count.index], "protocol", "") }"
  }
}

# Wrap the rendered port mappings in a JSON array

data "template_file" "_port_mappings" {
  template = <<JSON
"portMappings": [$${ports}]
JSON

  vars {
    ports = "${join(",",data.template_file._port_mapping.*.rendered)}"
  }
}

# Constructs the environment K/V from a map.
# Prevents an envar from being declared more than once, as is sensible

data "template_file" "_environment_keys" {
  count = "${length(keys(var.environment))}"

  template = <<JSON
{
  "name": $${name},
  "value":$${value}
}
JSON

  vars {
    name  = "${jsonencode( element(keys(var.environment), count.index) )}"
    value = "${jsonencode( lookup(var.environment, element(keys(var.environment), count.index)) )}"
  }
}

data "template_file" "_environment_list" {
  template = <<JSON
  "environment": [$${environment}]
JSON

  vars {
    environment = "${join(",",data.template_file._environment_keys.*.rendered)}"
  }
}

# Done this way because of module boundaries casting booleans to 0 and 1

data "template_file" "_mount_keys" {
  count = "${length(var.mount_points)}"

  template = <<JSON
{$${join(",",
  compact(
    list(
      "$${jsonencode("sourceVolume")}: $${jsonencode(sourceVolume)}",
      "$${jsonencode("containerPath")}: $${jsonencode(containerPath)}",
      read_only == "" ? "" : "$${jsonencode("readOnly")} : $${read_only == 1 ? true : false}"  
    )
  )
)}}
JSON

  vars {
    sourceVolume  = "${lookup(var.mount_points[count.index], "source_volume")}"
    containerPath = "${lookup(var.mount_points[count.index], "container_path")}"
    read_only     = "${lookup(var.mount_points[count.index], "read_only", "")}"
  }
}

# create the mount list via concatenating the two previous steps

data "template_file" "_mount_list" {
  template = <<JSON
"mountPoints": [$${mounts}]
JSON

  vars {
    mounts = "${join(",",data.template_file._mount_keys.*.rendered)}"
  }
}

# create the volume_from elements

data "template_file" "_volumes_from_keys" {
  count = "${length(var.volumes_from)}"

  template = <<JSON
{$${join(",",
  compact(
    list(
      "$${jsonencode("sourceContainer")}: $${jsonencode(sourceContainer)}",
      read_only == "" ? "" : "$${jsonencode("readOnly")} : $${read_only == 1 ? true : false}"  
    )
  )
)}}
JSON

  vars {
    sourceContainer = "${lookup(var.volumes_from[count.index], "source_container")}"
    read_only       = "${lookup(var.volumes_from[count.index], "read_only", "")}"
  }
}

# concatenate a list out of the rendered dicts

data "template_file" "_volumes_from_list" {
  # This should construct a normal list
  template = <<JSON
"volumesFrom": [$${volumes}]
JSON

  vars {
    volumes = "${join(",",data.template_file._volumes_from_keys.*.rendered)}"
  }
}

data "template_file" "_log_configuration_driver" {
  template = "$${driver}"
  vars {
    driver = "${ length(var.logging_driver) > 0
      ? "${jsonencode("logDriver")}: ${ jsonencode(var.logging_driver) }"
      : ""
      }"
  }
}



data "template_file" "_log_configuration_options" {
  # Will become an empty string
  template = "${jsonencode("options")}: ${jsonencode(var.logging_options)}"
}


data "template_file"  "_log_configuration" {
  template = "{$${configuration}}"
  vars {
    configuration = "${join(",",
        compact(
          list(
            data.template_file._log_configuration_driver.rendered,
            data.template_file._log_configuration_options.rendered
          )
        )
    )}"
  }
}

# Builds the final rendered dict
# Ideally, this would cat the dict out through jq and ensure that it's a valid
# JSON blob, but doing so may not be a reasonable (or even easy) action to 
# Take, so it's probably best to not do that.

data "template_file" "_final" {
  template = <<JSON
  [{
    $${val}
  }]
JSON

  vars {
    val = "${join(",",
      compact(
        list(
          "${jsonencode("name")}: ${jsonencode(var.name)}",
          "${jsonencode("image")}: ${jsonencode(var.image)}",
          "${var.cpu != "" ? "${jsonencode("cpu")}: ${var.cpu}" : "" }",
          "${var.memory != "" ? "${jsonencode("memory")}: ${var.memory}" : "" }",
          "${var.essential != "" ? data.template_file.essential.rendered : ""}",
          "${length(var.links) > 0 ? "${jsonencode("links")}: ${jsonencode(var.links)}" : ""}",
          "${length(var.port_mappings) > 0 ?  data.template_file._port_mappings.rendered : ""}",
          "${length(keys(var.environment)) > 0 ? data.template_file._environment_list.rendered : "" }",
          "${length(var.mount_points) > 0 ? data.template_file._mount_list.rendered : "" }",
          "${length(var.volumes_from) > 0 ? data.template_file._volumes_from_list.rendered : "" }",
          "${length(var.command) > 0 ? "${jsonencode("command")}: ${jsonencode(var.command)}" : "" }",
          "${ length(var.logging_driver) > 0
            ? "${jsonencode("logConfiguration")}: ${data.template_file._log_configuration.rendered}"
            : ""
            }",
          )
        )
      )}"
  }
}

          /**/
