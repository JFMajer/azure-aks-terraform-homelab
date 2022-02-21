resource "azurerm_resource_group" "aks_rg" {
  name     = "${var.app-prefix}-${var.env}-rg"
  location = var.location
}

resource "random_id" "log_analytics_workspace_name_suffix" {
  byte_length = 8
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.app-prefix}-${var.env}-law-${random_id.log_analytics_workspace_name_suffix.dec}"
  location            = var.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  sku                 = "PerGB2018"
}

resource "azurerm_kubernetes_cluster" "k8s" {
  name                = "${var.app-prefix}-${var.env}-aks"
  location            = var.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = "${var.app-prefix}-${var.env}-aks"

  linux_profile {
    admin_username = "ubuntu"
    ssh_key {
      key_data = file(var.ssh_public_key)
    }
  }

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s"
  }

  service_principal {
    client_id     = var.service_principal_client_id
    client_secret = var.service_principal_client_secret
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "Standard"
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
    }
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "np" {
  name                  = "aksspotpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.k8s.id
  node_count            = 2
  vm_size               = "Standard_D2S_v5"
  mode                  = "User"
  priority              = "Spot"
}

resource "azurerm_mysql_flexible_server" "mysql" {
  name                   = "${var.app-prefix}-${var.env}-mysql"
  location               = var.location
  resource_group_name    = azurerm_resource_group.aks_rg.name
  sku_name               = "B_Standard_B1s"
  version                = 5.7
  backup_retention_days  = 7
  administrator_login    = "dbadmin"
  administrator_password = random_string.random.result
}

resource "random_string" "random" {
  length           = 16
  special          = true
  override_special = "/@£$"
}