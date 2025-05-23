variable "flavor" {
  type    = string
  default = "2"
}

variable "image_id" {
  type = string
  default = "829a7888-b7ee-4022-bc20-75f0f444f607"
}

variable "volume_size" {
  type    = number
  default = 20
}

variable "keypair" {
  type = string
  default = "myk8skey"
}

variable "private_key_path" {
  description = "ssh private key path"
  type = string
  default = "/root/.ssh/myk8skey.pem"
}

variable "volume_names" {
  description = "volume list"
  type = list(string)
  default     = ["volume-bastion2", "volume-haproxy2", "volume-web3", "volume-web4"]
}
