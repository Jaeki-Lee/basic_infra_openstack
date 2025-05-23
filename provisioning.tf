# resource "null_resource" "provision_bastion" {
#   # web4.id 와 fip_web4.address 가 바뀔 때마다 다시 실행
#     triggers = {
#         bastion_id = openstack_compute_instance_v2.bastion.id
#         fip     = openstack_compute_floatingip_associate_v2.fip_bastion.floating_ip
#     }   
#     # Floating IP 연결이 반드시 끝난 후에 실행되도록
#     depends_on = [
#         openstack_compute_instance_v2.bastion,
#         openstack_compute_instance_v2.haproxy,
#         openstack_compute_instance_v2.web3,
#         openstack_compute_instance_v2.web4,
#         openstack_compute_floatingip_associate_v2.fip_bastion,
#         openstack_compute_floatingip_associate_v2.fip_haproxy,
#         openstack_compute_floatingip_associate_v2.fip_web3,
#         openstack_compute_floatingip_associate_v2.fip_web4
#     ]

#     connection {
#         type        = "ssh"
#         user        = "ubuntu"
#         private_key = file(var.private_key_path)
#         host        = openstack_networking_floatingip_v2.fip_bastion.address
#     }

#     # Copy private key for bastion to SSH into internal hosts
#     provisioner "file" {
#         source      = var.private_key_path
#         destination = "/home/ubuntu/.ssh/myk8skey"
#     }

#     provisioner "remote-exec" {
#         inline = [
#           "chmod 700 /home/ubuntu/.ssh",
#           "chmod 600 /home/ubuntu/.ssh/myk8skey",
#           "chmod 600 /home/ubuntu/.ssh/config"
#         ]
#     }

#   # Install nothing else here: bastion uses SSH proxy
#     provisioner "file" {
#         content     = <<-EOF
#           Host haproxy2
#             HostName ${openstack_compute_instance_v2.haproxy.network.0.fixed_ip_v4}
#             User ubuntu
#             IdentityFile ~/.ssh/myk8skey

#           Host web3
#             HostName ${openstack_compute_instance_v2.web3.network.0.fixed_ip_v4}
#             User ubuntu
#             IdentityFile ~/.ssh/myk8skey

#           Host web4
#             HostName ${openstack_compute_instance_v2.web4.network.0.fixed_ip_v4}
#             User ubuntu
#             IdentityFile ~/.ssh/myk8skey
#         EOF

#         destination = "/home/ubuntu/.ssh/config"
#     }
# }

# resource "null_resource" "provision_haproxy" {
#   triggers = {
#     haproxy_id = openstack_compute_instance_v2.haproxy.id
#     fip        = openstack_networking_floatingip_v2.fip_haproxy.address
#   }
#   depends_on = [
#     openstack_compute_floatingip_associate_v2.fip_haproxy,
#     openstack_compute_instance_v2.web3,
#     openstack_compute_floatingip_associate_v2.fip_web3,
#     openstack_compute_instance_v2.web4,
#     openstack_compute_floatingip_associate_v2.fip_web4,
#   ]

#   connection {
#     type        = "ssh"
#     user        = "ubuntu"
#     private_key = file(var.private_key_path)
#     host        = openstack_networking_floatingip_v2.fip_haproxy.address
#     timeout = "50m"
#   }

#   # 1) haproxy 설치
#   provisioner "remote-exec" {
#     inline = [
#       "sudo apt update",
#       "sudo apt install -y haproxy",
#       "sudo systemctl enable haproxy",
#       "sudo systemctl start haproxy"
#     ]
#   }

#   # 2) cfg 파일 올리기
#   provisioner "file" {
#     content     = <<-EOF
#       # haproxy.cfg
#       global
#           daemon
#           maxconn 2000

#       defaults
#           mode http
#           timeout connect 5s
#           timeout client  30s
#           timeout server  30s

#       frontend http-in
#           bind *:80
#           default_backend webpool

#       backend webpool
#           balance roundrobin
#           server web3 ${openstack_compute_instance_v2.web3.network.0.fixed_ip_v4}:80 check
#           server web4 ${openstack_compute_instance_v2.web4.network.0.fixed_ip_v4}:80 check
#     EOF
#     destination = "/tmp/haproxy.cfg"
#   }

#   # 3) 설정 파일 배치 및 서비스 재시작
#   provisioner "remote-exec" {
#     inline = [
#       "sudo mv /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg",
#       "sudo systemctl reload haproxy"
#     ]
#   }
# }
