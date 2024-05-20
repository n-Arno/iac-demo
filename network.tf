locals {
  subnet = "192.168.0.0/24"
}

resource "scaleway_vpc" "demo" {
  name = format("vpc-demo-%s", var.env)
  tags = ["demo", var.env]
}

resource "scaleway_vpc_private_network" "demo" {
  name   = format("pn-demo-%s", var.env)
  vpc_id = scaleway_vpc.demo.id
  ipv4_subnet {
    subnet = local.subnet
  } 
  tags   = ["demo", var.env]
}

resource "scaleway_vpc_public_gateway_ip" "demo" {
}

resource "scaleway_vpc_public_gateway" "demo" {
  name       = format("gw-demo-%s", var.env)
  type       = "VPC-GW-M"
  ip_id      = scaleway_vpc_public_gateway_ip.demo.id
  tags       = ["demo", var.env]
  depends_on = [scaleway_vpc_private_network.demo]
  # to avoid race conditions, create PGW after PN
}

resource "scaleway_vpc_gateway_network" "demo" {
  gateway_id         = scaleway_vpc_public_gateway.demo.id
  private_network_id = scaleway_vpc_private_network.demo.id
  enable_masquerade  = true
  ipam_config {
    push_default_route = true
  }
}

resource "time_sleep" "wait_for_pgw" {
  # wait 20s after creating the PGW network.
  depends_on      = [scaleway_vpc_gateway_network.demo]
  create_duration = "20s"
}
