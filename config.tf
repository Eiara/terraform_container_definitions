terraform {
  experiments = [module_variable_optional_attrs]
}

locals {
  mount_points_in = defaults(
    var.mount_points,
    {
      read_only = true
    }
  )
}
