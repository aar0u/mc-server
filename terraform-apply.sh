ip=$(curl -s https://ipinfo.io | jq -r ".ip")
terraform taint azurerm_virtual_machine.papermc_vm
terraform apply -var="username=azureuser" -var="source_ip=$ip"
