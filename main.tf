# https://github.com/spring-projects/spring-petclinic

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "sample_app" {
  name     = "petclinic-application-1"
  location = "West Europe"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "sample_app" {
  name                = "sample_app-network"
  resource_group_name = azurerm_resource_group.sample_app.name
  location            = azurerm_resource_group.sample_app.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "sample_app" {
  name                 = "acctsub"
  resource_group_name  = azurerm_resource_group.sample_app.name
  virtual_network_name = azurerm_virtual_network.sample_app.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "sample_app" {
  name                = "sample_app_ip"
  location            = azurerm_resource_group.sample_app.location
  resource_group_name = azurerm_resource_group.sample_app.name
  allocation_method   = "Static"
  domain_name_label   = azurerm_resource_group.sample_app.name

  tags = {
    environment = "staging"
  }
}

resource "azurerm_lb" "sample_app" {
  name                = "sample_app_lb"
  location            = azurerm_resource_group.sample_app.location
  resource_group_name = azurerm_resource_group.sample_app.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.sample_app.id
  }
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  resource_group_name = azurerm_resource_group.sample_app.name
  loadbalancer_id     = azurerm_lb.sample_app.id
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "sample_app" {
  resource_group_name = azurerm_resource_group.sample_app.name
  loadbalancer_id     = azurerm_lb.sample_app.id
  name                = "http-probe"
  protocol            = "Http"
  request_path                = "/"
  port                =  80
}

resource "azurerm_lb_rule" "web_lbrule" {
  name = "sample-app-WEB-lbrule"
  resource_group_name = azurerm_resource_group.sample_app.name          
  loadbalancer_id = azurerm_lb.sample_app.id                            
  frontend_ip_configuration_name = "PublicIPAddress"     
  protocol = "Tcp"
  frontend_port = 80
  backend_port = 80
  probe_id = "${azurerm_lb_probe.sample_app.id}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.bpepool.id}"
}


resource "azurerm_linux_virtual_machine_scale_set" "sample_app" {
  name                = "sample_app_scaleset-1"
  location            = azurerm_resource_group.sample_app.location
  resource_group_name = azurerm_resource_group.sample_app.name

  # required when using rolling upgrade policy
  health_probe_id = azurerm_lb_probe.sample_app.id

  sku                 = "Standard_F2"
  instances           = 2
  admin_username       = "myadmin"
  admin_password       = "Password1234!"
  computer_name_prefix = "sampleApp"
  
  disable_password_authentication = false
  custom_data  = filebase64("user-data.sh")

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.7"
    version   = "latest"
  }


  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "TestIPConfiguration"
      primary                                = true
      subnet_id                              = azurerm_subnet.sample_app.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
    }
  }

  tags = {
    environment = "staging"
  }
}

resource "azurerm_monitor_autoscale_setting" "VMSS_autoscale" {

  name                      = "sample_app_autoscale_setting"
  location                  = azurerm_resource_group.sample_app.location
  resource_group_name       = azurerm_resource_group.sample_app.name
  target_resource_id        = azurerm_linux_virtual_machine_scale_set.sample_app.id
  
    profile {
		name = "defaultProfile"

		capacity {
		  default = 2
		  minimum = 2
		  maximum = 5
		}

		rule {
		  metric_trigger {
			metric_name        = "Percentage CPU"
			metric_resource_id = azurerm_linux_virtual_machine_scale_set.sample_app.id
			time_grain         = "PT1M"
			statistic          = "Average"
			time_window        = "PT5M"
			time_aggregation   = "Average"
			operator           = "GreaterThan"
			threshold          = 75
			metric_namespace   = "microsoft.compute/virtualmachinescalesets"
			dimensions {
			  name     = "AppName"
			  operator = "Equals"
			  values   = ["App1"]
			}
		  }

		  scale_action {
			direction = "Increase"
			type      = "ChangeCount"
			value     = "1"
			cooldown  = "PT1M"
		  }
		}

		rule {
		  metric_trigger {
			metric_name        = "Percentage CPU"
			metric_resource_id = azurerm_linux_virtual_machine_scale_set.sample_app.id
			time_grain         = "PT1M"
			statistic          = "Average"
			time_window        = "PT5M"
			time_aggregation   = "Average"
			operator           = "LessThan"
			threshold          = 25
		  }

		  scale_action {
			direction = "Decrease"
			type      = "ChangeCount"
			value     = "1"
			cooldown  = "PT1M"
		  }
		}

	}
}




output "public_ip_address" {
  value = azurerm_public_ip.sample_app.ip_address
}

output "DNS" {
  value = azurerm_public_ip.sample_app.fqdn
}
