locals {
  networks = {
    private4 = "172.16.4.0/24"
    private5 = "172.16.5.0/24"
    private6 = "172.16.6.0/24"
  }
}

resource "openstack_networking_network_v2" "private" {
  for_each = local.networks
  name = each.key
}

resource "openstack_networking_subnet_v2" "private" {
  for_each = local.networks
  name = "${each.key}-subnet"
  network_id = openstack_networking_network_v2.private[each.key].id
  cidr = each.value
  ip_version = 4
  dns_nameservers = ["8.8.8.8"]
  gateway_ip = cidrhost(each.value, 1)
}

resource "openstack_networking_router_v2" "main" {
  name = "R2"
  external_network_id = "52be5bdc-1cde-447c-bf59-9155e99dbb6c" 
}

resource "openstack_networking_router_interface_v2" "if" {
  for_each = openstack_networking_subnet_v2.private
  router_id = openstack_networking_router_v2.main.id
  subnet_id = each.value.id
}