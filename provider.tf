terraform {
  required_version = ">= 0.13"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.5"    # 사용하려는 버전에 맞춰 조정
    }
  }
}

provider "openstack" {
  auth_url    = "http://211.183.3.11:5000/v3"
  tenant_name = "admin"
  user_name    = "admin"
  password    = "test123"
  domain_name = "default"
  region      = "RegionOne"
}