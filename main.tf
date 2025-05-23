# Instance 
# bastion
resource "openstack_compute_instance_v2" "bastion" {
    name = "bastion2"
    flavor_id = var.flavor
    key_pair = var.keypair
    security_groups = [openstack_networking_secgroup_v2.bastion-sg2.name]
    
    block_device {
        uuid = openstack_blockstorage_volume_v3.volumes["volume-bastion2"].id
        source_type = "volume"
        destination_type = "volume"
        delete_on_termination = true
        boot_index = 0
    }

    network {
        uuid = openstack_networking_network_v2.private["private4"].id
    }

    timeouts {
        create = "30m"
    }

    
    user_data = <<-EOF
          #!/bin/bash
          set -eux

          # 1) Install SSH client (should already be there on Ubuntu, but just in case)
          apt-get update -y
          apt-get install -y --no-install-recommends openssh-client

          # 2) Prep .ssh directory
          mkdir -p /home/ubuntu/.ssh
          chmod 700 /home/ubuntu/.ssh

          # 3) Inject your private key
          cat <<KEY > /home/ubuntu/.ssh/myk8skey
          ${file(var.private_key_path)}
          KEY
          chmod 600 /home/ubuntu/.ssh/myk8skey

          # 4) Write SSH config for internal hosts
          cat <<CONFIG > /home/ubuntu/.ssh/config
          Host haproxy2
            HostName ${openstack_compute_instance_v2.haproxy.network[0].fixed_ip_v4}
            User ubuntu
            IdentityFile ~/.ssh/myk8skey

          Host web3
            HostName ${openstack_compute_instance_v2.web3.network[0].fixed_ip_v4}
            User ubuntu
            IdentityFile ~/.ssh/myk8skey

          Host web4
            HostName ${openstack_compute_instance_v2.web4.network[0].fixed_ip_v4}
            User ubuntu
            IdentityFile ~/.ssh/myk8skey
            CONFIG
          chmod 600 /home/ubuntu/.ssh/config

          # 5) Fix ownership
          chown -R ubuntu:ubuntu /home/ubuntu/.ssh
          EOF

    lifecycle {
        create_before_destroy = false
    }
}

# haproxy
resource "openstack_compute_instance_v2" "haproxy" {
    name = "haproxy2"
    flavor_id = var.flavor
    key_pair = var.keypair
    security_groups = [openstack_networking_secgroup_v2.haproxy-web-sg2.name]
    block_device {
        uuid = openstack_blockstorage_volume_v3.volumes["volume-haproxy2"].id
        source_type = "volume"
        destination_type = "volume"
        delete_on_termination = true
        boot_index = 0
    }
    network {
        uuid = openstack_networking_network_v2.private["private5"].id
    }

    timeouts {
        create = "30m"
    }

    user_data = <<-EOT
            #!/bin/bash
            # 패키지 목록 업데이트
            #apt-get update -y

            # HAProxy 설치
            apt-get install -y haproxy

            # /etc/haproxy/haproxy.cfg 파일 내용 작성
            # 기존 파일이 있다면 덮어쓰기 위해 '>' 사용
            cat <<EOF > /etc/haproxy/haproxy.cfg
            global
               log /dev/log local0
               log /dev/log local1 notice
               chroot /var/lib/haproxy
               stats timeout 30s
               user haproxy
               group haproxy
               daemon

            defaults
               log global
               mode http
               option httplog
               option dontlognull
               timeout connect 5s
               timeout client 1m
               timeout server 1m

            frontend http_front
               bind *:80
               stats uri /haproxy?stats
               default_backend http_back

            backend http_back
               balance roundrobin
               server server_name1 ${openstack_compute_instance_v2.web3.network[0].fixed_ip_v4}:80 check
               server server_name2 ${openstack_compute_instance_v2.web4.network[0].fixed_ip_v4}:80 check
            EOF

            # HAProxy 서비스 활성화 (부팅 시 자동 시작) 및 재시작 (설정 적용)
            systemctl enable haproxy
            systemctl restart haproxy
            EOT

    lifecycle {
        create_before_destroy = false
    }
}

# web3
resource "openstack_compute_instance_v2" "web3" {
    name = "web3"
    flavor_id = var.flavor
    key_pair = var.keypair
    security_groups = [openstack_networking_secgroup_v2.haproxy-web-sg2.name]
    block_device {
        uuid = openstack_blockstorage_volume_v3.volumes["volume-web3"].id
        source_type = "volume"
        destination_type = "volume"
        delete_on_termination = true
        boot_index = 0
    }
    network {
        uuid = openstack_networking_network_v2.private["private6"].id
    }
    user_data = <<-EOF
          #!/bin/bash
          sudo apt update
          sudo apt install -y nginx
          sudo systemctl enable nginx
          sudo systemctl start nginx
    EOF
    timeouts {
        create = "30m"
    }
    lifecycle {
          create_before_destroy = false
    }
}

# web4
resource "openstack_compute_instance_v2" "web4" {
    name = "web4"
    flavor_id = var.flavor
    key_pair = var.keypair
    security_groups = [openstack_networking_secgroup_v2.haproxy-web-sg2.name]
    block_device {
        uuid = openstack_blockstorage_volume_v3.volumes["volume-web4"].id
        source_type = "volume"
        destination_type = "volume"
        delete_on_termination = true
        boot_index = 0
    }
    network {
        uuid = openstack_networking_network_v2.private["private6"].id
    }
    user_data = <<-EOF
          #!/bin/bash
          sudo apt update
          sudo apt install -y nginx
          sudo systemctl enable nginx
          sudo systemctl start nginx
    EOF
    timeouts {
        create = "30m"
    }
    lifecycle {
        create_before_destroy = false
    }
}

# Attach FloatingIP to instances
resource "openstack_networking_floatingip_v2" "fip_bastion" {
    pool       = "sharednet1"
}
resource "openstack_networking_floatingip_v2" "fip_haproxy" {
    pool       = "sharednet1"
}
resource "openstack_networking_floatingip_v2" "fip_web3" {
    pool       = "sharednet1"
}
resource "openstack_networking_floatingip_v2" "fip_web4" {
    pool       = "sharednet1"
}

#floating IP의 mapping
resource "openstack_compute_floatingip_associate_v2" "fip_bastion" {
    floating_ip = openstack_networking_floatingip_v2.fip_bastion.address  # 공인주소소
    instance_id = openstack_compute_instance_v2.bastion.id  # 어떤 인스턴스의의
    fixed_ip    = openstack_compute_instance_v2.bastion.network.0.fixed_ip_v4 # 어떤 사설주소(NIC)와 매핑
    wait_until_associated = true
}

resource "openstack_compute_floatingip_associate_v2" "fip_haproxy" {
    floating_ip = openstack_networking_floatingip_v2.fip_haproxy.address  # 공인주소소
    instance_id = openstack_compute_instance_v2.haproxy.id  # 어떤 인스턴스의의
    fixed_ip    = openstack_compute_instance_v2.haproxy.network.0.fixed_ip_v4 # 어떤 사설주소(NIC)와 매핑
    wait_until_associated = true
}

resource "openstack_compute_floatingip_associate_v2" "fip_web3" {
    floating_ip = openstack_networking_floatingip_v2.fip_web3.address  # 공인주소소
    instance_id = openstack_compute_instance_v2.web3.id  # 어떤 인스턴스의의
    fixed_ip    = openstack_compute_instance_v2.web3.network.0.fixed_ip_v4 # 어떤 사설주소(NIC)와 매핑
    wait_until_associated = true
}

resource "openstack_compute_floatingip_associate_v2" "fip_web4" {
    floating_ip = openstack_networking_floatingip_v2.fip_web4.address  # 공인주소소
    instance_id = openstack_compute_instance_v2.web4.id  # 어떤 인스턴스의의
    fixed_ip    = openstack_compute_instance_v2.web4.network.0.fixed_ip_v4 # 어떤 사설주소(NIC)와 매핑
    wait_until_associated = true
}
