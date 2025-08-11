
data "openstack_networking_network_v2" "internal_network" {
    name = "project_2011674" # Internal network which is the same name is my project name  
}

data "openstack_networking_network_v2" "public_network" {
  name = "public"
}

data "openstack_compute_flavor_v2" "flavor" {
  name = "standard.small"
}

data "openstack_images_image_v2" "image" {
  name = "Ubuntu-22.04"
}

resource "openstack_compute_keypair_v2" "keypair" {
  name       = "promvm"
  public_key = file("promvm.pub") 
}

resource "openstack_networking_secgroup_v2" "secgroup" {
  name        = "allow_ssh_and_9090"
  description = "Allow SSH (22) and port 9090"
}

resource "openstack_networking_secgroup_rule_v2" "ssh_rule" {
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "port_9090_rule" {
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 9090
  port_range_max    = 9090
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_port_v2" "port" {
  network_id = data.openstack_networking_network_v2.internal_network.id
}

resource "openstack_compute_instance_v2" "vm" {
  name       = "terraform-vm"
  image_id   = data.openstack_images_image_v2.image.id
  flavor_id  = data.openstack_compute_flavor_v2.flavor.id
  key_pair   = openstack_compute_keypair_v2.keypair.name
  security_groups = [openstack_networking_secgroup_v2.secgroup.name]

  network {
    port = openstack_networking_port_v2.port.id
  }
}

resource "openstack_networking_floatingip_v2" "floating_ip" {
  pool = data.openstack_networking_network_v2.public_network.name
}

resource "openstack_compute_floatingip_associate_v2" "fip_associate" {
  instance_id = openstack_compute_instance_v2.vm.id
  floating_ip = openstack_networking_floatingip_v2.floating_ip.address
}
output "instance_floating_ip" {
  description = "Floating IP address assigned to the instance"
  value       = openstack_networking_floatingip_v2.floating_ip.address
}
