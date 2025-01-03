locals {
  rg_shared = jsondecode(file("${path.module}/rg_shared.json"))
}

variable "data_disk_size_gb" {
  default = 32
}

resource "azurerm_managed_disk" "disk1" {
  name                 = "disk1"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = local.rg_shared.group_name
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb

  # This prevents the disk from being deleted when you destroy other resources
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_subnet" "subnet_papermc" {
  name                 = "subnet-papermc"
  resource_group_name  = local.rg_shared.group_name
  virtual_network_name = local.rg_shared.virtual_network_name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_lb_backend_address_pool" "lb_pool_papermc" {
  loadbalancer_id = local.rg_shared.lb_id
  name            = "lb-pool-papermc"
}

resource "azurerm_lb_nat_rule" "lb_pool_papermc_ssh" {
  resource_group_name            = local.rg_shared.group_name
  loadbalancer_id                = local.rg_shared.lb_id
  name                           = "lb-pool-papermc-ssh"
  protocol                       = "Tcp"
  frontend_port_start            = 2022
  frontend_port_end              = 2022
  backend_port                   = 22
  backend_address_pool_id        = azurerm_lb_backend_address_pool.lb_pool_papermc.id
  frontend_ip_configuration_name = local.rg_shared.frontend_ip_configuration_name
}

resource "azurerm_lb_rule" "lb_pool_papermc_app" {
  loadbalancer_id                = local.rg_shared.lb_id
  name                           = "lb-pool-papermc-app"
  protocol                       = "Tcp"
  frontend_port                  = 25665
  backend_port                   = 25665
  frontend_ip_configuration_name = local.rg_shared.frontend_ip_configuration_name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_pool_papermc.id]
  disable_outbound_snat          = true
}

resource "azurerm_network_interface_backend_address_pool_association" "papermc_nic_outbound" {
  network_interface_id  = azurerm_network_interface.papermc_nic.id
  ip_configuration_name =  azurerm_network_interface.papermc_nic.ip_configuration[0].name
  backend_address_pool_id = local.rg_shared.lb_pool_outbound_id
}