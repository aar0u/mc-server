resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = var.target_group_name
}

resource "azurerm_network_interface" "papermc_nic" {
  name                = "${var.target_group_name}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "${var.target_group_name}-nic-ip-conf"
    subnet_id                     = azurerm_subnet.subnet_papermc.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "papermc_nic_inbound" {
  network_interface_id    = azurerm_network_interface.papermc_nic.id
  ip_configuration_name   = azurerm_network_interface.papermc_nic.ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_pool_papermc.id
}

resource "azurerm_network_security_group" "papermc_nsg" {
  name                = "${var.target_group_name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowFromMyIP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "80", "443"]
    source_address_prefix      = var.source_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Public"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["25665"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Allow ports from Public"
  }
}

resource "azurerm_network_interface_security_group_association" "papermc_nsg_association" {
  network_interface_id      = azurerm_network_interface.papermc_nic.id
  network_security_group_id = azurerm_network_security_group.papermc_nsg.id
}

resource "azurerm_virtual_machine" "papermc_vm" {
  name                          = var.target_group_name
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  network_interface_ids         = [azurerm_network_interface.papermc_nic.id]
  vm_size                       = "Standard_B2ls_v2"
  delete_os_disk_on_termination = true

  plan {
    publisher = "resf"
    product   = "rockylinux-x86_64"
    name      = "9-base"
  }

  storage_os_disk {
    name              = "${var.target_group_name}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }

  storage_image_reference {
    publisher = "resf"
    offer     = "rockylinux-x86_64"
    sku       = "9-base"
    version   = "latest"
  }

  os_profile {
    computer_name  = var.target_group_name
    admin_username = var.username
    custom_data = base64encode(<<-EOF
      #!/bin/bash
      sudo dnf install tmux java-21-openjdk tree -y

      DISK="/dev/sdb"
      MOUNT_POINT="/mnt/newdisk"
      TIMEOUT=300  # Timeout in seconds
      INTERVAL=5   # Interval in seconds
      ELAPSED=0

      # Wait for the disk to be attached
      while [ ! -b $DISK ]; do
        if [ $ELAPSED -ge $TIMEOUT ]; then
          echo "Error: Disk $DISK not available after $TIMEOUT seconds."
          exit 1
        fi
        echo "Waiting for disk $DISK to be available..."
        sleep $INTERVAL
        ELAPSED=$((ELAPSED + INTERVAL))
      done

      # Check if disk is formatted
      if ! blkid $DISK; then
        # Format disk if not formatted
        mkfs.ext4 $DISK
      fi

      # Create mount point
      mkdir -p $MOUNT_POINT

      # Add to fstab if not already present
      if ! grep -q "$DISK" /etc/fstab; then
        echo "$DISK $MOUNT_POINT ext4 defaults 0 0" >> /etc/fstab
      fi

      # Mount the disk
      mount $MOUNT_POINT

      # Set permissions
      chown -R ${var.username}:${var.username} $MOUNT_POINT

      # Runscript for minecraft server
      cat << 'EOL' > /home/${var.username}/run.sh
      cd /mnt/newdisk/mc-server
      tmux new-session -d -s papermc "java -Xms1024M -Xmx3072M -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar paper-1.20.4-497.jar nogui"
      sleep 30
      tmux send-keys -t papermc "$(cat << EOC
      say Server is now online!
      gamerule keepInventory true
      gamerule doDaylightCycle false
      time set day
      lp group default permission set fawe.permpack.basic true
      lp group default permission set fawe.bypass true
      lp group default permission set minecraft.command.selector true
      lp group default permission set minecraft.command.teleport true
      EOC
      )" C-m
      EOL

      # Make run.sh executable
      chmod +x /home/${var.username}/run.sh
    EOF
    )
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.username}/.ssh/authorized_keys"
      key_data = var.public_key
    }
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "papermc_disk_attachment" {
  managed_disk_id    = azurerm_managed_disk.disk1.id
  virtual_machine_id = azurerm_virtual_machine.papermc_vm.id
  lun                = "10"
  caching            = "ReadWrite"
}
