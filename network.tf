resource "azurerm_virtual_network" "jamesooo_lb_demo" {
  for_each = azurerm_resource_group.jamesooo_lb_demo

  name                = "vnet-${each.key}"
  address_space = ["10.0.0.0/16"]
  resource_group_name = each.value.name
  location            = each.value.location
}

resource "azurerm_subnet" "vnet" {
  for_each = azurerm_resource_group.jamesooo_lb_demo

  name                 = "vnet-subnet-${each.key}"
  resource_group_name  = azurerm_resource_group.jamesooo_lb_demo[each.value.location].name
  virtual_network_name = azurerm_virtual_network.jamesooo_lb_demo[each.value.location].name
  address_prefixes     = ["10.0.0.0/24"]

  depends_on = [ azurerm_virtual_network.jamesooo_lb_demo ]
}

resource "azurerm_subnet" "bastion" {
  for_each = azurerm_resource_group.jamesooo_lb_demo

  name                 = "AzureBastionSubnet"
  resource_group_name  = each.value.name
  virtual_network_name = azurerm_virtual_network.jamesooo_lb_demo[each.value.location].name
  address_prefixes     = ["10.0.1.0/24"]

  depends_on = [ 
    azurerm_virtual_network.jamesooo_lb_demo,
    azurerm_subnet.vnet,
   ]
}

resource "azurerm_public_ip" "frontend" {
  for_each = azurerm_resource_group.jamesooo_lb_demo

  name                    = "frontend-${each.value.location}"
  location                = azurerm_resource_group.jamesooo_lb_demo[each.value.location].location
  resource_group_name     = azurerm_resource_group.jamesooo_lb_demo[each.value.location].name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
  sku = "Standard"

  tags = {
    environment = "frontend-${each.value.location}"
  }
}

# output "frontend_ip" {
  # value = azurerm_public_ip.frontend.*.ip_address
# }

resource "azurerm_public_ip" "bastion" {
  for_each = azurerm_resource_group.jamesooo_lb_demo

  name                    = "bastion-${each.value.location}"
  location                = azurerm_resource_group.jamesooo_lb_demo[each.value.location].location
  resource_group_name     = azurerm_resource_group.jamesooo_lb_demo[each.value.location].name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
  sku = "Standard"

  tags = {
    environment = "bastion-${each.key}"
  }
}

# output "bastion_ip" {
  # value = azurerm_public_ip.bastion.*.ip_address
# }

resource "azurerm_public_ip" "outbound" {
  for_each = azurerm_resource_group.jamesooo_lb_demo

  name                    = "outbound-${each.value.location}"
  location                = azurerm_resource_group.jamesooo_lb_demo[each.value.location].location
  resource_group_name     = azurerm_resource_group.jamesooo_lb_demo[each.value.location].name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
  sku = "Standard"

  tags = {
    environment = "outbound-${each.key}"
  }
}

# output "outbound_ip" {
  # value = azurerm_public_ip.outbound.*.ip_address
# }

resource "azurerm_network_security_group" "jamesooo_lb_demo" {
  for_each = azurerm_resource_group.jamesooo_lb_demo

  name                = "security-group-${each.key}"
  location            = azurerm_resource_group.jamesooo_lb_demo[each.key].location
  resource_group_name = azurerm_resource_group.jamesooo_lb_demo[each.key].name

  security_rule {
    name                       = "Allow-HTTP-${each.key}"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}
