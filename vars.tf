variable "instances" {
  type = map(object({
    name                      = string
    count                     = number
    region                    = string
  }))
  description = "The instance(s) that will be created."
  default = {
    "single-1" = {
      name   = "jamesooo-lb-demo-default-1"
      count  = 1
      region = "westus3"
    },
  }
}

locals {
  username             = "jamesooo"

  instance_regions     = [for instance in var.instances : instance.region]

  # Create a map of instances with the count expanded such that the map includes an entry for every instance to be created
  expanded_instances = flatten([for instance in var.instances : [
    for i in range(instance.count) : {
      name                      = "${instance.name}-${i}",
      region                    = instance.region,
  }]])
}
