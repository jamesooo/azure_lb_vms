resource "azurerm_resource_group" "jamesooo_lb_demo" {
  for_each = toset(local.instance_regions)

  name     = "jamesooo_lb_demo_${each.value}"
  location = each.value
}
