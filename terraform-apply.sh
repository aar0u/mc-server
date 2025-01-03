ip=$(curl -s https://ipinfo.io | jq -r ".ip")

read -n 1 -r -p "Do you want to re-create the VM? (y/n): "
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    terraform taint azurerm_virtual_machine.papermc_vm
fi

terraform apply -var="username=azureuser" -var="source_ip=$ip"
