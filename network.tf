resource "azurerm_virtual_network" "jamesooo_lb_demo" {
  for_each = azurerm_resource_group.jamesooo_lb_demo

  name                = "vnet_${each.key}"
  address_space = ["10.0.0.0/16"]
  resource_group_name = each.value.name
  location            = each.value.location
}

resource "azurerm_subnet" "vnet" {
  for_each = azurerm_resource_group.jamesooo_lb_demo

  name                 = "vnet_subnet_${each.key}"
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

  name                    = "frontend_${each.value.location}"
  location                = azurerm_resource_group.jamesooo_lb_demo[each.value.location].location
  resource_group_name     = azurerm_resource_group.jamesooo_lb_demo[each.value.location].name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
  sku = "Standard"

  tags = {
    environment = "frontend_${each.value.location}"
  }
}

output "frontend_ip_addresses" {
  description = "The IP address, and FQDN for all frontend public IPs."
  value = {
    for region in local.instance_regions : region => {
      ip_address = azurerm_public_ip.frontend[region].ip_address
      fqdn       = azurerm_public_ip.frontend[region].fqdn
    }
  }
}

resource "azurerm_public_ip" "bastion" {
  for_each = azurerm_resource_group.jamesooo_lb_demo

  name                    = "bastion_${each.value.location}"
  location                = azurerm_resource_group.jamesooo_lb_demo[each.value.location].location
  resource_group_name     = azurerm_resource_group.jamesooo_lb_demo[each.value.location].name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
  sku = "Standard"

  tags = {
    environment = "bastion_${each.key}"
  }
}

output "bastion_ip_addresses" {
  description = "The IP address, and FQDN for all bastion public IPs."
  value = {
    for region in local.instance_regions : region => {
      ip_address = azurerm_public_ip.bastion[region].ip_address
      fqdn       = azurerm_public_ip.bastion[region].fqdn
    }
  }
}

resource "azurerm_public_ip" "outbound" {
  for_each = azurerm_resource_group.jamesooo_lb_demo

  name                    = "outbound_${each.value.location}"
  location                = azurerm_resource_group.jamesooo_lb_demo[each.value.location].location
  resource_group_name     = azurerm_resource_group.jamesooo_lb_demo[each.value.location].name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
  sku = "Standard"

  tags = {
    environment = "outbound_${each.key}"
  }
}

output "outbound_ip_addresses" {
  description = "The IP address, and FQDN for all outbound public IPs."
  value = {
    for region in local.instance_regions : region => {
      ip_address = azurerm_public_ip.outbound[region].ip_address
      fqdn       = azurerm_public_ip.outbound[region].fqdn
    }
  }
}
resource "azurerm_network_security_group" "jamesooo_lb_demo" {
  for_each = azurerm_resource_group.jamesooo_lb_demo

  name                = "security_group_${each.key}"
  location            = azurerm_resource_group.jamesooo_lb_demo[each.key].location
  resource_group_name = azurerm_resource_group.jamesooo_lb_demo[each.key].name

  security_rule {
    name                       = "Allow_HTTP_${each.key}"
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
