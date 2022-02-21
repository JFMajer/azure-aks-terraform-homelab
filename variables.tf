variable "env" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "francecentral"
}

variable "app-prefix" {
  type    = string
  default = "k8s-app"
}

variable "ssh_public_key" {
  default = "~/.ssh/id_rsa.pub"
}

variable "service_principal_client_id" {}
variable "service_principal_client_secret" {}
variable "db_password" {}