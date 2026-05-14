# IPs públicas de las VMs (para SSH y para el inventory de Ansible)
output "vm1_public_ip" {
  description = "IP pública de VM-Linux-01"
  value       = azurerm_public_ip.pip_vm1.ip_address
}

output "vm2_public_ip" {
  description = "IP pública de VM-Linux-02"
  value       = azurerm_public_ip.pip_vm2.ip_address
}

# IP y dominio del Load Balancer (usar este dominio para el certificado SSL)
output "lb_public_ip" {
  description = "IP pública del Load Balancer"
  value       = azurerm_public_ip.pip_lb.ip_address
}

output "lb_domain_name" {
  description = "Nombre de dominio del LB — usar este para Let's Encrypt"
  value       = azurerm_public_ip.pip_lb.fqdn
}
