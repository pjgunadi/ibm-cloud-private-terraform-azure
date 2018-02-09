output "icp_url" {
  value = "https://${azurerm_public_ip.master_pip.0.ip_address}:8443"
}
