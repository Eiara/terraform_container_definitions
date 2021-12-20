variable "name" {
  type = string
  description = ""
}

variable "image" {
  type = string
  description = ""
}

variable "essential" {
  type = bool
  default = false
  description = ""
}

variable "memory" {
  type = number
  default     = 1
  description = ""
  validation {
    condition = var.memory > 0
    error_message = "Memory must be greater than 0."
  }
}

variable "cpu" {
  type = number
  default     = 1
  description = ""
  validation {
    condition = var.cpu > 0
    error_message = "CPU must be greater than 0."
  }
}

variable "port_mappings" {
  # type        = list(object({
  #   container_port = number
  #   host_port = optional(number)
  #   protocol = optional(string)
  # }))
  type = list(map(string))
  default     = []
  description = ""
  validation {
    condition = (length(var.port_mappings) == 0 ||
    (
      alltrue( [ for obj in var.port_mappings : contains(["tcp", "udp", "TCP", "UDP", ""], lookup(obj, "protocol", ""))] ) &&
      alltrue( [ for obj in var.port_mappings: obj.container_port > 0 ] ) &&
      alltrue( [ for obj in var.port_mappings: lookup(obj, "host_port", -1) == -1 || lookup(obj, "host_port") > 0 ] )
    ))
    error_message = "Port mapping is incorrect."
  }
}

variable "links" {
  type        = list(string)
  default     = []
  description = ""
}

variable "entry_point" {
  type        = list(string)
  default     = []
  description = ""
}

variable "command" {
  type = list(string)
  default     = []
  description = ""
}

variable "working_directory" {
  type = string
  default     = ""
  description = ""
}

variable "environment" {
  type        = map(string)
  default     = {}
  description = ""
}

variable "disable_networking" {
  type = string
  default     = ""
  description = ""
}

variable "hostname" {
  type = string
  default     = ""
  description = ""
}

variable "dns_servers" {
  type = list(string)
  default     = []
  description = ""
}

variable "dns_search_domains" {
  type = list(string)
  default     = []
  description = ""
}

variable "extra_hosts" {
  type = list(string)
  default     = []
  description = ""
}

variable "read_only_root_filesystem" {
  type = bool
  default     = false
  description = ""
}

variable "mount_points" {
  type = list(object({
    source_volume = string
    container_path = string
    # I wish optional let you set a default for it instead of it being null
    read_only = optional(bool)
  }))
  default     = []
  description = "a list of mount point maps, of the form source_volume, container_path, and optional read-only"
  validation {
    # TODO:
    #   This should support Windows absolute container paths, since it doesn't
    condition = alltrue([for mp in var.mount_points: can(regex("^/*", mp.container_path)) ])
    error_message = "In-container mount points must be absolute."
  }
}

variable "volumes_from" {
  type = list(object({
    source_container = string
    read_only = optional(bool)
  }))
  default     = []
  description = "a list of maps"
}

variable "logging_driver" {
  default = ""
  type = string
  description = "logging configuration"
  validation {
    condition = var.logging_driver == "" || contains(["awslogs","fluentd","gelf","json-file","journald","logentries","splunk","syslog","awsfirelens"], var.logging_driver)
    error_message = "Invalid logging driver name."
  }
}
variable "logging_options" {
  default = {}
  type = map(string)
  description = ""
}

variable "logging_secret_options" {
  type = map(string)
  description = "Secret options for logging"
  default = {}
  sensitive = true
}


variable "health_check" {
  type = object({
    retries = number
    command = list(string)
    timeout = number
    interval = number
  })
  description = "health check details"
  default = {
    retries = 1
    command = [
      "CMD-SHELL",
      "exit 0" # default to a null/always succeed health check
    ]
    timeout = 5
    interval = 30 # doesn't need to run super often by default
  }
}
