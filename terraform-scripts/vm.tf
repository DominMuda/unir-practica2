# Creamos una máquina virtual
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine

resource "azurerm_linux_virtual_machine" "myVM" {
    name                = var.vms[count.index]
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    size                = var.vm_size
    admin_username      = "adminUsername"
    network_interface_ids = [ azurerm_network_interface.myNic[count.index].id ]
    disable_password_authentication = true
    count = length(var.vms)

    admin_ssh_key {
        username   = "adminUsername"
        public_key = file("~/.ssh/id_rsa.pub")
    }

    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    plan {
        name      = "centos-8-stream-free"
        product   = "centos-8-stream-free"
        publisher = "cognosys"
    }

    source_image_reference {
        publisher = "cognosys"
        offer     = "centos-8-stream-free"
        sku       = "centos-8-stream-free"
        version   = "1.2019.0810"
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.stAccount.primary_blob_endpoint
    }

    tags = {
        environment = "CP2"
    }
}

resource "azurerm_managed_disk" "nfsdata" {
    name                 = "nfs-data-disk1"
    location             = azurerm_resource_group.rg.location
    resource_group_name  = azurerm_resource_group.rg.name
    storage_account_type = "Standard_LRS"
    create_option        = "Empty"
    disk_size_gb         = 10
}

resource "azurerm_virtual_machine_data_disk_attachment" "example" {
    count = length(var.vms)
    managed_disk_id    = azurerm_managed_disk.nfsdata.id
    virtual_machine_id = azurerm_linux_virtual_machine.myVM[0].id
    lun                = "10"
    caching            = "ReadWrite"
}