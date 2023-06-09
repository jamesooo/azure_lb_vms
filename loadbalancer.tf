resource "azurerm_lb" "jamesooo_lb_demo" {
  for_each = azurerm_resource_group.jamesooo_lb_demo

  name                = "jamesooo_lb_demo"
  location            = each.value.location
  resource_group_name = each.value.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "Frontend_${each.value.location}"
    public_ip_address_id = azurerm_public_ip.frontend[each.key].id
  }
  frontend_ip_configuration {
    name                 = "Outbound_${each.value.location}"
    public_ip_address_id = azurerm_public_ip.outbound[each.key].id
  }

  depends_on = [
    azurerm_public_ip.frontend,
    azurerm_public_ip.outbound,
  ]
}

resource "azurerm_lb_backend_address_pool" "backend" {
  for_each = azurerm_lb.jamesooo_lb_demo

  loadbalancer_id = each.value.id
  name            = "BackEndAddressPool_${each.value.location}"
}

resource "azurerm_lb_backend_address_pool" "backend_outbound" {
  for_each = azurerm_lb.jamesooo_lb_demo

  loadbalancer_id = each.value.id
  name            = "BackEndAddressPoolOutbound_${each.value.location}"
}

resource "azurerm_lb_rule" "jamesooo_lb_demo" {
  for_each = azurerm_lb.jamesooo_lb_demo

  name                           = "HTTPRule_${each.value.name}"
  loadbalancer_id                = each.value.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "Frontend_${each.value.location}"
  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.backend[each.value.location].id
  ]
  enable_floating_ip      = false
  idle_timeout_in_minutes = 15
  enable_tcp_reset        = true
  disable_outbound_snat   = true
  probe_id                = azurerm_lb_probe.jamesooo_lb_demo[each.value.location].id
}

resource "azurerm_lb_probe" "jamesooo_lb_demo" {
  for_each = azurerm_lb.jamesooo_lb_demo

  loadbalancer_id     = each.value.id
  name                = "http_probe_${each.value.name}"
  port                = 80
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_outbound_rule" "jamesooo_lb_demo" {
  for_each = azurerm_lb.jamesooo_lb_demo

  name                     = "Outbound_${each.value.location}"
  loadbalancer_id          = each.value.id
  protocol                 = "All"
  backend_address_pool_id  = azurerm_lb_backend_address_pool.backend_outbound[each.value.location].id
  allocated_outbound_ports = 10000
  enable_tcp_reset         = false
  idle_timeout_in_minutes  = 15

  frontend_ip_configuration {
    name = "Outbound_${each.value.location}"
  }
}
