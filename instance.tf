resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_virtual_machine" "jamesooo_lb_demo" {
  for_each = { for instance in local.expanded_instances : instance.name => instance }

  name                  = "${each.value.name}"
  location              = azurerm_resource_group.jamesooo_lb_demo[each.value.region].location
  resource_group_name   = azurerm_resource_group.jamesooo_lb_demo[each.value.region].name
  network_interface_ids = [azurerm_network_interface.jamesooo_lb_demo[each.value.name].id]
  vm_size               = "Standard_DS1_v2"

  # This is just an example environemnt I don't want to keep the data
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "${each.value.name}_osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = replace("${each.value.name}", "_", "-")
    admin_username = local.username
    admin_password = random_password.password.result
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }

  depends_on = [ azurerm_network_interface.jamesooo_lb_demo ]
}

resource "azurerm_virtual_machine_extension" "install_web_server" {
  for_each = azurerm_virtual_machine.jamesooo_lb_demo

  name                 = "install_web_server"
  virtual_machine_id   = each.value.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
 {
  "commandToExecute": "sudo apt-get -y update && sudo env DEBIAN_FRONTEND=noninteractive apt-get -y install apache2 && sudo systemctl start apache2 && sudo systemctl enable apache2 && sudo echo '<h1>Hello World from ${each.value.name}</h1>' | sudo tee /var/www/html/index.html"
 }
SETTINGS


  tags = {
    environment = "Production"
  }

  depends_on = [ azurerm_virtual_machine.jamesooo_lb_demo ]
}

resource "azurerm_network_interface" "jamesooo_lb_demo" {
  for_each = { for instance in local.expanded_instances : instance.name => instance }

  name                = "network_interface_${each.value.name}"
  location            = each.value.region
  resource_group_name = azurerm_resource_group.jamesooo_lb_demo[each.value.region].name

  ip_configuration {
    name                          = "internal-${each.value.name}"
    subnet_id                     = azurerm_subnet.vnet[each.value.region].id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    azurerm_lb.jamesooo_lb_demo,
    azurerm_network_security_group.jamesooo_lb_demo,
    azurerm_virtual_network.jamesooo_lb_demo,
    azurerm_subnet.vnet,
  ]
}

resource "azurerm_network_interface_backend_address_pool_association" "backend" {
  for_each = azurerm_virtual_machine.jamesooo_lb_demo

  network_interface_id    = azurerm_network_interface.jamesooo_lb_demo[each.value.name].id
  ip_configuration_name   = "internal-${each.value.name}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend[each.value.location].id
}

resource "azurerm_network_interface_backend_address_pool_association" "backend_outbound" {
  for_each = azurerm_virtual_machine.jamesooo_lb_demo

  network_interface_id    = azurerm_network_interface.jamesooo_lb_demo[each.value.name].id
  ip_configuration_name   = "internal-${each.value.name}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_outbound[each.value.location].id
}

resource "azurerm_bastion_host" "jamesooo_lb_demo" {
  for_each = azurerm_resource_group.jamesooo_lb_demo

  name                = "bastion_${each.value.location}"
  location            = each.value.location
  resource_group_name = each.value.name

  ip_configuration {
    name                 = "bastion_${each.value.location}"
    subnet_id            = azurerm_subnet.bastion[each.value.location].id
    public_ip_address_id = azurerm_public_ip.bastion[each.value.location].id
  }

  depends_on = [
    azurerm_public_ip.bastion,
    azurerm_virtual_network.jamesooo_lb_demo,
  ]
}
