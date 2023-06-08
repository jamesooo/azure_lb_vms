resource "azurerm_resource_group" "jamesooo_lb_demo" {
  for_each = toset(local.instance_regions)

  name     = "jamesooo_lb_demo-${each.value}"
  location = each.value
}

# output "resource_group_id" {
  # value = azurerm_resource_group.jamesooo_lb_demo.*.id
# }
