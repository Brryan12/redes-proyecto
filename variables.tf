variable "subscription_id" {
  description = "ID de tu suscripción de Azure for Students"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "Llave SSH pública para acceder a las VMs"
  type        = string
}

variable "location" {
  description = "Región de Azure"
  type        = string
  default     = "canadacentral"
}

variable "resource_group_name" {
  description = "Nombre del Resource Group"
  type        = string
  default     = "redes"
}

variable "admin_username" {
  description = "Usuario administrador de las VMs"
  type        = string
  default     = "azureuser"
}
