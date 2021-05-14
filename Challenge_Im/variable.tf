variable "subnet_prefix" {
    type = list
    default = [
        { cidr_block = "10.0.1.0/24", name = "pub_subnet_1" },
        { cidr_block = "10.0.2.0/24", name = "pub_subnet_2" },
        { cidr_block = "10.0.3.0/24", name = "pub_subnet_3" },
        { cidr_block = "10.0.4.0/24", name = "priv_subnet_1" },
        { cidr_block = "10.0.5.0/24", name = "priv_subnet_2" },
        { cidr_block = "10.0.6.0/24", name = "priv_subnet_3" }
    ]
}

variable "ubuntu_account_number" {
  default = "099720109477" 
}

variable "profile" {
  default = "awssandbox" #IAM Named Profile if  applicable
}

variable "key_name" {
  default = "im-ec2-key"  #Please change this default key to a key that you have access to
}