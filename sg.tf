resource "openstack_networking_secgroup_v2" "bastion-sg2" {
  name = "bastion-sg2"
  description = "Allow SSH, icmp access to bastion host"
}

resource "openstack_networking_secgroup_rule_v2" "bastion-sg2-rule" {
  for_each = {
    ssh  = { port = 22, protocol = "tcp"}
    icmp = { protocol = "icmp" }
  }

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = each.value.protocol
  port_range_min    = lookup(each.value, "port", null)
  port_range_max    = lookup(each.value, "port", null)
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.bastion-sg2.id
}

resource "openstack_networking_secgroup_v2" "haproxy-web-sg2" {
  name = "haproxy-web-sg2"
  description = "Allow SSH, HTTP, ICMP haproxy, web host"
}

resource "openstack_networking_secgroup_rule_v2" "haproxy-web-sg-rule2" {
  for_each = {
    ssh  = { port = 22, protocol = "tcp" }
    http = { port = 80, protocol = "tcp" }
    icmp = { protocol = "icmp" }
  }

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = each.value.protocol
  port_range_min    = lookup(each.value, "port", null)
  port_range_max    = lookup(each.value, "port", null)
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.haproxy-web-sg2.id
}