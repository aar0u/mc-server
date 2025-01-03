variable "resource_group_location" {
  default     = "southeastasia"
  description = "Location of the resource group."
}

variable "resource_group_name" {
  default     = "mcraft"
  description = "Resource group name."
}

variable "prefix" {
  default     = "papermc"
  description = "Prefix for resource names."
}

variable "domain_name_label" {
  default     = "bcmcraft"
  description = "Domain name label for the public IP."
}

variable "username" {
  default     = "azureuser"
  description = "The username for the local account that will be created on the new VM."
}

variable "public_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDX0B543UN5echyv/Fvd5pHJpbB3GMMV6YAovhZwYRiSBUgp7GFUMA6fz19tArF5GmH0isLcDs7SXvi9AILNr6FmmaiBsEqfXKC7wtxVamhpFInkIMJDvNKTvpnTit6oUJ4Zx30v+53zakib7ak6i9PojU/ZJtWjZp6mSU7znlKJkbrZK41nu00pH3A6idi4Ti6MfMJ3sORfQqCG7exftXgXRUj/BsVetIPHx68n+7sUcOT8USMES9D3LHGX/zWdUnAjBBUa8o5S29o33OKc+3/V4KBqXtd+WMilFkvc2/IMULB5q8LohEdUo1WupquJx75PVDoOfIZ6TqwhIZgxXwDkT7r7fn1R7jsSt33gqoGMzQOH7MIGzw9qlejlIWe17ELicH/EWHEwR/VIHgvsuO15utoC5HepwbKalwK3rWoe5sZEEDrM6iEVE6DUn+1gZqvUYhIncwRu8/vMw5QpySA2jxXleBanF/XjJyyA/RC4Pas+l36Q0wuBNa+MZQUyIk= generated-by-azure"
  description = "SSH public key for authentication."
}

variable "source_ip" {
  description = "The IP to access the new VM."
}

variable "data_disk_size_gb" {
  default     = 32
  description = "Size of the data disk in GB"
}
