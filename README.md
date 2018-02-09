# Terraform Template for ICP Deployment in Microsoft Azure

## Before you start
You need a Azure account and be aware that **applying this template may incur charges to your Azure account**.

## Summary
This terraform template perform the following tasks:
- Provision Azure environment for IBM Cloud Private
- [Provision ICP from external module](https://github.com/pjgunadi/terraform-module-icp-deploy)

### Prerequisite: Azure Subscription
You need to have Azure subscription with sufficient quota of cores. Visit this [link](https://docs.microsoft.com/en-us/azure/azure-subscription-service-limits) for more details.

## Deployment step from Terraform CLI
1. Clone this repository: `git clone https://github.com/pjgunadi/ibm-cloud-private-terraform-azure.git`
2. [Download terraform](https://www.terraform.io/) if you don't have one
3. Download and install [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
4. Rename [terraform_tfvars.sample](terraform_tfvars.sample) file as `terraform.tfvars` and update the input values as needed.
5. Initialize Terraform
```
terraform init
```
6. Login to Azure with CLI `az login` and follow its instruction to authenticate. [More details](https://docs.microsoft.com/en-us/cli/azure/?view=azure-cli-latest#az_login)
7. Review Terraform plan
```
terraform plan
```
8. Apply Terraform template
```
terraform apply
```

## Add/Remove Worker Nodes
1. Edit existing deployed terraform variable e.g. `terraform.tfvars`
2. Increase/decrease the `nodes` under the `worker` map variable. Example:
```
worker = {
    nodes       = "4"
    name        = "worker"
    vm_size     = "Standard_A4_v2"
    kubelet_lv  = "10"
    docker_lv   = "89"
}
```
**Note:** The data disk size is the sume of LV variables + 1 (e.g kubelet_lv + docker_lv + 1).  
3. Re-apply terraform template:
```
terraform plan
terraform apply -auto-approve
```
## ICP Provisioning Module
The ICP Installation is performed by [ICP Provisioning module](https://github.com/pjgunadi/terraform-module-icp-deploy) 
