# This is done because boolean values cross the module boundary as 0 and 1,
# So we need to cheaply cast it back to the literal of `false` and `true`


locals {
  # camelCasing this is going to suuuuck isn't it

  port_mappings = (length(var.port_mappings) == 0
    ? {}
    : { portMappings = [ for mapping in var.port_mappings :
        { for k, v in mapping :
          try("${split("_", k)[0]}${title(split("_", k)[1])}", k) => tonumber(v)
        }
    ]}
  )
  environment = {
    environment = [ for k, v in var.environment : {
      name = k
      value = v
    } ]
  }

  # Needs to have read_only marked as optional or removed
  mount_points = {
    mountPoints = [ for mount in local.mount_points_in :
      { for k, v in mount :
        try("${split("_", k)[0]}${title(split("_", k)[1])}", k) => v
      }
    ]
  }
  # Needs to have read_only marked as optional or removed
  volumes_from = {
    volumesFrom = [ for volume in var.volumes_from :
      { for k, v in volume :
        try("${split("_", k)[0]}${title(split("_", k)[1])}", k) => v
      }
    ]
  }
  log_configuration = (var.logging_driver == "" ? {} : {
      logConfiguration = merge(
        {logDriver = var.logging_driver},
        length(keys(var.logging_options)) == 0 ? {} : { options = var.logging_options},
        length(keys(var.logging_secret_options)) == 0 ? {} : { secretOptions = var.logging_secret_options }
      )
    }
  )

  output = merge(
    { name = var.name },
    { image = var.image },
    var.cpu == null ? {} : { cpu = var.cpu },
    var.memory == null ? {} : { memory = var.memory },
    { essential = var.essential },
    length(var.links) == 0 ? {} : { links = var.links },
    length(var.port_mappings) == 0 ? {} : local.port_mappings,
    length(keys(var.environment)) == 0 ? {} : local.environment,
    length(var.mount_points) == 0 ? {} : local.mount_points,
    length(var.volumes_from) == 0 ? {} : local.volumes_from,
    local.volumes_from,
    local.log_configuration,
    length(var.command) == 0 ? {} : { command = var.command }
  )
}
