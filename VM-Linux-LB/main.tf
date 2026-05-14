# ============================================================
# Provider
# ============================================================
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.72.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# ============================================================
# Resource Group
# ============================================================
resource "azurerm_resource_group" "rg" {
  name     = "redes"
  location = "canadacentral"
}

# ============================================================
# Virtual Network — VM-Linux-01-vnet (10.0.0.0/16)
# ============================================================
resource "azurerm_virtual_network" "vnet" {
  name                = "VM-Linux-01-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

# ============================================================
# Network Security Group
# ============================================================
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-web"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # SSH — solo para administración
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # HTTPS — tráfico principal del sitio web
  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # HTTP — necesario para el probe del LB y para redirigir a HTTPS con NGINX
  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# ============================================================
# IPs públicas de las VMs (para acceso SSH directo)
# ============================================================
resource "azurerm_public_ip" "pip_vm1" {
  name                = "pip-VM-Linux-01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "pip_vm2" {
  name                = "pip-VM-Linux-02"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# ============================================================
# Interfaces de red (mismos nombres que los existentes)
# ============================================================
resource "azurerm_network_interface" "nic_vm1" {
  name                = "vm-linux-01948"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_vm1.id
  }
}

resource "azurerm_network_interface" "nic_vm2" {
  name                = "vm-linux-02671"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_vm2.id
  }
}

# ============================================================
# VM-Linux-01 — Ubuntu 22.04
# ============================================================
resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "VM-Linux-01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B2ats_v2"
  admin_username      = "azureuser"

  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.nic_vm1.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-22_04-lts"
    sku       = "server"
    version   = "latest"
  }

  boot_diagnostics {}
}

# ============================================================
# VM-Linux-02 — Ubuntu 22.04 (imagen idéntica a VM1)
# ============================================================
resource "azurerm_linux_virtual_machine" "vm2" {
  name                = "VM-Linux-02"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B2ats_v2"
  admin_username      = "azureuser"

  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.nic_vm2.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-22_04-lts"
    sku       = "server"
    version   = "latest"
  }

  boot_diagnostics {}
}

# ============================================================
# IP Pública del Load Balancer
# Zone-redundant (zonas 1, 2, 3) igual que la existente
# Se agrega domain_name_label para Let's Encrypt
# Dominio: redes-proyecto.canadacentral.cloudapp.azure.com
# ============================================================
resource "azurerm_public_ip" "pip_lb" {
  name                = "IP-LB"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]

  # Cambia este label si quieres otro nombre de dominio
  domain_name_label   = "redes-proyecto"
}

# ============================================================
# Load Balancer Standard
# ============================================================
resource "azurerm_lb" "lb" {
  name                = "Load"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "front-Proyecto"
    public_ip_address_id = azurerm_public_ip.pip_lb.id
  }
}

# Backend pool — agrupa las dos VMs Linux
resource "azurerm_lb_backend_address_pool" "backend" {
  name            = "linux"
  loadbalancer_id = azurerm_lb.lb.id
}

# Asociar NIC de VM1 al backend pool
resource "azurerm_network_interface_backend_address_pool_association" "vm1_backend" {
  network_interface_id    = azurerm_network_interface.nic_vm1.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend.id
}

# Asociar NIC de VM2 al backend pool
resource "azurerm_network_interface_backend_address_pool_association" "vm2_backend" {
  network_interface_id    = azurerm_network_interface.nic_vm2.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend.id
}

# Probe HTTP — puerto 80
resource "azurerm_lb_probe" "probe_http" {
  name                = "Sondeo-NGINX"
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = "Tcp"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 1
}

# Probe HTTPS — puerto 443
resource "azurerm_lb_probe" "probe_https" {
  name                = "Sondeo-NGINX-443"
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = "Tcp"
  port                = 443
  interval_in_seconds = 5
  number_of_probes    = 1
}

# Regla HTTP — puerto 80
resource "azurerm_lb_rule" "rule_http" {
  name                           = "Regla-HTTP-80"
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "front-Proyecto"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend.id]
  probe_id                       = azurerm_lb_probe.probe_http.id
  load_distribution              = "SourceIP"
  disable_outbound_snat          = false
  idle_timeout_in_minutes        = 4
}

# Regla HTTPS — puerto 443
resource "azurerm_lb_rule" "rule_https" {
  name                           = "Regla-HTTPS-443"
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "front-Proyecto"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend.id]
  probe_id                       = azurerm_lb_probe.probe_https.id
  load_distribution              = "SourceIP"
  disable_outbound_snat          = false
  idle_timeout_in_minutes        = 4
}
