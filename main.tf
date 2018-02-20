provider "azurerm" {
#  subscription_id = "${var.subscription_id}"
#  client_id       = "${var.aad_client_id}"
#  client_secret   = "${var.aad_client_secret}"
#  tenant_id       = "${var.tenant_id}"
}
#Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group}"
  location = "${var.location}"
}
#Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.virtual_network_name}"
  location            = "${var.location}"
  address_space       = "${var.address_spaces}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}
#Route Table
resource "azurerm_route_table" "routetb" {
  name                = "${var.route_table_name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group}"
}
#Subnetwork
resource "azurerm_subnet" "subnet" {
  name                 = "${var.subnet_name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefix       = "${var.subnet_prefix}"
  route_table_id       = "${azurerm_route_table.routetb.id}"
}
#Network Security Group - Master
resource "azurerm_network_security_group" "master_sg" {
  name                = "${var.cluster_name}-${var.master["name"]}-sg"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "${var.cluster_name}-${var.master["name"]}-ssh"
    description                = "Allow inbound SSH from all locations"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "${var.cluster_name}-${var.master["name"]}-icp"
    description                = "Allow inbound ICPUI from all locations"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "${var.cluster_name}-${var.master["name"]}-kube"
    description                = "Allow inbound kubectl from all locations"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8001"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "${var.cluster_name}-${var.master["name"]}-registry"
    description                = "Allow inbound docker registry from all locations"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8500"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "${var.cluster_name}-${var.master["name"]}-monitoring"
    description                = "Allow inbound Monitoring from all locations"
    priority                   = 500
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "4300"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "${var.cluster_name}-${var.proxy["name"]}-nodeport"
    description                = "Allow inbound Nodeport from all locations"
    priority                   = 600
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }  
  security_rule {
    name                       = "${var.cluster_name}-${var.master["name"]}-liberty"
    description                = "Allow inbound Liberty from all locations"
    priority                   = 700
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }  
}
#Network Security Group - Proxy
resource "azurerm_network_security_group" "proxy_sg" {
  name                = "${var.cluster_name}-${var.proxy["name"]}-sg"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "${var.cluster_name}-${var.proxy["name"]}-ssh"
    description                = "Allow inbound SSH from all locations"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "${var.cluster_name}-${var.proxy["name"]}-nodeport"
    description                = "Allow inbound Nodeport from all locations"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
#Network Security Group - Management and Worker
resource "azurerm_network_security_group" "worker_sg" {
  name                = "${var.cluster_name}-worker-sg"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "${var.cluster_name}-worker-ssh"
    description                = "Allow inbound SSH from all locations"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
#Public IP
resource "azurerm_public_ip" "master_pip" {
  count                        = "${var.master["nodes"]}"
  name                         = "${var.master["name"]}-pip-${count.index}"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  public_ip_address_allocation = "Static"
  domain_name_label            = "${var.cluster_name}-${var.master["name"]}-${count.index}"
}
resource "azurerm_public_ip" "proxy_pip" {
  count                        = "${var.proxy["nodes"]}"
  name                         = "${var.proxy["name"]}-pip-${count.index}"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  public_ip_address_allocation = "Static"
  domain_name_label            = "${var.cluster_name}-${var.proxy["name"]}-${count.index}"
}
#Network Interface
resource "azurerm_network_interface" "master_nic" {
  count               = "${var.master["nodes"]}"
  name                = "${var.master["name"]}-nic-${count.index}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.master_sg.id}"

  ip_configuration {
    name                          = "${var.master["name"]}-ipcfg-${count.index}"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.master_pip.*.id, count.index)}"
  }
}
resource "azurerm_network_interface" "proxy_nic" {
  count               = "${var.proxy["nodes"]}"
  name                = "${var.proxy["name"]}-nic-${count.index}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.proxy_sg.id}"

  ip_configuration {
    name                          = "${var.proxy["name"]}-ipcfg-${count.index}"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.proxy_pip.*.id, count.index)}"
  }
}
resource "azurerm_network_interface" "management_nic" {
  count               = "${var.management["nodes"]}"
  name                = "${var.management["name"]}-nic-${count.index}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.worker_sg.id}"

  ip_configuration {
    name                          = "${var.management["name"]}-ipcfg-${count.index}"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_network_interface" "worker_nic" {
  count               = "${var.worker["nodes"]}"
  name                = "${var.worker["name"]}-nic-${count.index}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.worker_sg.id}"

  ip_configuration {
    name                          = "${var.worker["name"]}-ipcfg-${count.index}"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "Dynamic"
  }
}
#Storage
resource "azurerm_managed_disk" "master_datadisk" {
  count                = "${var.master["nodes"]}"
  name                 = "${var.master["name"]}-datadisk-${count.index}"
  location             = "${var.location}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  storage_account_type = "${var.storage_account_tier}_${var.storage_replication_type}"
  create_option        = "Empty"
  disk_size_gb         = "${var.master["kubelet_lv"] + var.master["docker_lv"] + var.master["registry_lv"] + var.master["etcd_lv"] + var.master["management_lv"] + 1}"
}
resource "azurerm_managed_disk" "proxy_datadisk" {
  count                = "${var.proxy["nodes"]}"
  name                 = "${var.proxy["name"]}-datadisk-${count.index}"
  location             = "${var.location}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  storage_account_type = "${var.storage_account_tier}_${var.storage_replication_type}"
  create_option        = "Empty"
  disk_size_gb         = "${var.proxy["kubelet_lv"] + var.proxy["docker_lv"] + 1}"
}
resource "azurerm_managed_disk" "management_datadisk" {
  count                = "${var.management["nodes"]}"
  name                 = "${var.management["name"]}-datadisk-${count.index}"
  location             = "${var.location}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  storage_account_type = "${var.storage_account_tier}_${var.storage_replication_type}"
  create_option        = "Empty"
  disk_size_gb         = "${var.management["kubelet_lv"] + var.management["docker_lv"] + var.management["management_lv"] + 1}"
}
resource "azurerm_managed_disk" "worker_datadisk" {
  count                = "${var.worker["nodes"]}"
  name                 = "${var.worker["name"]}-datadisk-${count.index}"
  location             = "${var.location}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  storage_account_type = "${var.storage_account_tier}_${var.storage_replication_type}"
  create_option        = "Empty"
  disk_size_gb         = "${var.worker["kubelet_lv"] + var.worker["docker_lv"] + 1}"
}

#Private Key
resource "tls_private_key" "azkey" {
  algorithm = "RSA"

  provisioner "local-exec" {
    command = "cat > ${var.ssh_key_name} <<EOL\n${tls_private_key.azkey.private_key_pem}\nEOL"
  }  
}

#Script Template
data "template_file" "createfs_master" {
  template = "${file("${path.module}/scripts/createfs_master.sh.tpl")}"
  vars {
    kubelet_lv = "${var.master["kubelet_lv"]}"
    docker_lv = "${var.master["docker_lv"]}"
    etcd_lv = "${var.master["etcd_lv"]}"
    registry_lv = "${var.master["registry_lv"]}"
    management_lv = "${var.master["management_lv"]}"
  }
}
data "template_file" "createfs_proxy" {
  template = "${file("${path.module}/scripts/createfs_proxy.sh.tpl")}"
  vars {
    kubelet_lv = "${var.proxy["kubelet_lv"]}"
    docker_lv = "${var.proxy["docker_lv"]}"
  }
}
data "template_file" "createfs_management" {
  template = "${file("${path.module}/scripts/createfs_management.sh.tpl")}"
  vars {
    kubelet_lv = "${var.management["kubelet_lv"]}"
    docker_lv = "${var.management["docker_lv"]}"
    management_lv = "${var.management["management_lv"]}"
  }
}
data "template_file" "createfs_worker" {
  template = "${file("${path.module}/scripts/createfs_worker.sh.tpl")}"
  vars {
    kubelet_lv = "${var.worker["kubelet_lv"]}"
    docker_lv = "${var.worker["docker_lv"]}"
  }
}

#Virtual Machines
#Master
resource "azurerm_virtual_machine" "master" {
  count                 = "${var.master["nodes"]}"
  name                  = "${var.master["name"]}-${count.index}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  vm_size               = "${var.master["vm_size"]}"
  network_interface_ids = ["${element(azurerm_network_interface.master_nic.*.id, count.index)}"]

  storage_image_reference {
    publisher = "${lookup(var.os_image_map, join("_publisher", list(var.os_image, "")))}"
    offer     = "${lookup(var.os_image_map, join("_offer", list(var.os_image, "")))}"
    sku       = "${lookup(var.os_image_map, join("_sku", list(var.os_image, "")))}"
    version   = "${lookup(var.os_image_map, join("_version", list(var.os_image, "")))}"
  }

  storage_os_disk {
    name              = "${var.master["name"]}-osdisk-${count.index}"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  storage_data_disk {
    name              = "${var.master["name"]}-datadisk-${count.index}"
    managed_disk_id   = "${element(azurerm_managed_disk.master_datadisk.*.id,count.index)}"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = "${var.master["kubelet_lv"] + var.master["docker_lv"] + var.master["registry_lv"] + var.master["etcd_lv"] + 1}"
    create_option     = "Attach"
    lun               = 0
  }

  os_profile {
    computer_name  = "${var.master["name"]}-${count.index}"
    admin_username = "${var.admin_username}"
    #admin_password = "${var.admin_password}"
    custom_data    = "${data.template_file.createfs_master.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${tls_private_key.azkey.public_key_openssh}"
    }    
  }
}
#Proxy
resource "azurerm_virtual_machine" "proxy" {
  count                 = "${var.proxy["nodes"]}"
  name                  = "${var.proxy["name"]}-${count.index}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  vm_size               = "${var.proxy["vm_size"]}"
  network_interface_ids = ["${element(azurerm_network_interface.proxy_nic.*.id, count.index)}"]

  storage_image_reference {
    publisher = "${lookup(var.os_image_map, join("_publisher", list(var.os_image, "")))}"
    offer     = "${lookup(var.os_image_map, join("_offer", list(var.os_image, "")))}"
    sku       = "${lookup(var.os_image_map, join("_sku", list(var.os_image, "")))}"
    version   = "${lookup(var.os_image_map, join("_version", list(var.os_image, "")))}"
  }

  storage_os_disk {
    name              = "${var.proxy["name"]}-osdisk-${count.index}"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  storage_data_disk {
    name              = "${var.proxy["name"]}-datadisk-${count.index}"
    managed_disk_id   = "${element(azurerm_managed_disk.proxy_datadisk.*.id,count.index)}"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = "${var.proxy["kubelet_lv"] + var.proxy["docker_lv"] + 1}"
    create_option     = "Attach"
    lun               = 0
  }

  os_profile {
    computer_name  = "${var.proxy["name"]}-${count.index}"
    admin_username = "${var.admin_username}"
    #admin_password = "${var.admin_password}"
    custom_data    = "${data.template_file.createfs_proxy.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${tls_private_key.azkey.public_key_openssh}"
    }      
  }
}
#Management
resource "azurerm_virtual_machine" "management" {
  count                 = "${var.management["nodes"]}"
  name                  = "${var.management["name"]}-${count.index}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  vm_size               = "${var.management["vm_size"]}"
  network_interface_ids = ["${element(azurerm_network_interface.management_nic.*.id, count.index)}"]

  storage_image_reference {
    publisher = "${lookup(var.os_image_map, join("_publisher", list(var.os_image, "")))}"
    offer     = "${lookup(var.os_image_map, join("_offer", list(var.os_image, "")))}"
    sku       = "${lookup(var.os_image_map, join("_sku", list(var.os_image, "")))}"
    version   = "${lookup(var.os_image_map, join("_version", list(var.os_image, "")))}"
  }

  storage_os_disk {
    name              = "${var.management["name"]}-osdisk-${count.index}"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  storage_data_disk {
    name              = "${var.management["name"]}-datadisk-${count.index}"
    managed_disk_id   = "${element(azurerm_managed_disk.management_datadisk.*.id,count.index)}"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = "${var.management["kubelet_lv"] + var.management["docker_lv"] + var.management["management_lv"] + 1}"
    create_option     = "Attach"
    lun               = 0
  }

  os_profile {
    computer_name  = "${var.management["name"]}-${count.index}"
    admin_username = "${var.admin_username}"
    #admin_password = "${var.admin_password}"
    custom_data    = "${data.template_file.createfs_management.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${tls_private_key.azkey.public_key_openssh}"
    }      
  }
}
# Worker
resource "azurerm_virtual_machine" "worker" {
  count                 = "${var.worker["nodes"]}"
  name                  = "${var.worker["name"]}-${count.index}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  vm_size               = "${var.worker["vm_size"]}"
  network_interface_ids = ["${element(azurerm_network_interface.worker_nic.*.id, count.index)}"]

  storage_image_reference {
    publisher = "${lookup(var.os_image_map, join("_publisher", list(var.os_image, "")))}"
    offer     = "${lookup(var.os_image_map, join("_offer", list(var.os_image, "")))}"
    sku       = "${lookup(var.os_image_map, join("_sku", list(var.os_image, "")))}"
    version   = "${lookup(var.os_image_map, join("_version", list(var.os_image, "")))}"
  }

  storage_os_disk {
    name              = "${var.worker["name"]}-osdisk-${count.index}"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  storage_data_disk {
    name              = "${var.worker["name"]}-datadisk-${count.index}"
    managed_disk_id   = "${element(azurerm_managed_disk.worker_datadisk.*.id,count.index)}"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = "${var.worker["kubelet_lv"] + var.worker["docker_lv"] + 1}"
    create_option     = "Attach"
    lun               = 0
  }

  os_profile {
    computer_name  = "${var.worker["name"]}-${count.index}"
    admin_username = "${var.admin_username}"
    #admin_password = "${var.admin_password}"
    custom_data    = "${data.template_file.createfs_worker.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${tls_private_key.azkey.public_key_openssh}"
    }      
  }
}

module "icpprovision" {
  source = "github.com/pjgunadi/terraform-module-icp-deploy"
  #source = "./icp-module"
  //Connection IPs
  #icp-ips = "${concat(azurerm_public_ip.master_pip.*.ip_address, azurerm_public_ip.proxy_pip.*.ip_address, azurerm_public_ip.management_pip.*.ip_address, azurerm_public_ip.worker_pip.*.ip_address)}"
  icp-ips = "${concat(azurerm_network_interface.master_nic.*.private_ip_address, azurerm_network_interface.proxy_nic.*.private_ip_address, azurerm_network_interface.management_nic.*.private_ip_address, azurerm_network_interface.worker_nic.*.private_ip_address)}"
  boot-node = "${element(azurerm_public_ip.master_pip.*.ip_address, 0)}"

  //Configuration IPs
  icp-master = ["${azurerm_network_interface.master_nic.*.private_ip_address}"]
  icp-worker = ["${azurerm_network_interface.worker_nic.*.private_ip_address}"]
  #icp-proxy = ["${azurerm_network_interface.proxy_nic.*.private_ip_address}"]
  icp-proxy = ["${azurerm_network_interface.master_nic.*.private_ip_address}"]
  icp-management = ["${azurerm_network_interface.management_nic.*.private_ip_address}"]

  icp-version = "${var.icp_version}"

  icp_source_server = "${var.icp_source_server}"
  icp_source_user = "${var.icp_source_user}"
  icp_source_password = "${var.icp_source_password}"
  image_file = "${var.icp_source_path}"

  # Workaround for terraform issue #10857
  # When this is fixed, we can work this out autmatically
  
  cluster_size  = "${var.master["nodes"] + var.worker["nodes"] + var.proxy["nodes"] + var.management["nodes"]}"

  icp_configuration = {
    "network_cidr"              = "${var.network_cidr}"
    "service_cluster_ip_range"  = "${var.cluster_ip_range}"
    "ansible_user"              = "${var.admin_username}"
    "ansible_become"            = "${var.admin_username == "root" ? false : true}"
    "default_admin_password"    = "${var.icpadmin_password}"
    "calico_ipip_enabled"       = "true"
    "docker_log_max_size"       = "10m"
    "docker_log_max_file"       = "10"
    "cluster_access_ip"         = "${element(azurerm_public_ip.master_pip.*.ip_address, 0)}"
    #"proxy_access_ip"           = "${element(azurerm_public_ip.proxy_pip.*.ip_address, 0)}"
    "proxy_access_ip"           = "${element(azurerm_public_ip.master_pip.*.ip_address, 0)}"
    "calico_ip_autodetection_method" = "can-reach=${azurerm_network_interface.master_nic.0.private_ip_address}"    
  }

  #Gluster
  #Gluster and Heketi nodes are set to worker nodes for demo. Use separate nodes for production
  install_gluster = "${var.install_gluster}"
  gluster_size = "${var.worker["nodes"]}" 
  gluster_ips = ["${azurerm_network_interface.worker_nic.*.private_ip_address}"] #Connecting IP
  gluster_svc_ips = ["${azurerm_network_interface.worker_nic.*.private_ip_address}"] #Service IP
  device_name = "/dev/xvdg" #update according to the device name provided by cloud provider
  heketi_ip = "${azurerm_network_interface.worker_nic.0.private_ip_address}" #Connecting IP
  heketi_svc_ip = "${azurerm_network_interface.worker_nic.0.private_ip_address}" #Service IP
  cluster_name = "${var.cluster_name}.icp"

  generate_key = true
  #icp_pub_keyfile = "${tls_private_key.azkey.public_key_openssh}"
  #icp_priv_keyfile = "${tls_private_key.azkey.private_key_pem}"
    
  ssh_user  = "${var.admin_username}"
  ssh_key   = "${tls_private_key.azkey.private_key_pem}"

  bastion_host = "${azurerm_public_ip.master_pip.0.ip_address}"
  bastion_user = "${var.admin_username}"
  bastion_private_key = "${tls_private_key.azkey.private_key_pem}"
} 
