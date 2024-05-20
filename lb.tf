resource "scaleway_lb_ip" "demo" {
}

resource "scaleway_lb" "demo" {
  ip_ids = [scaleway_lb_ip.demo.id]
  name  = "lb-demo"
  type  = "LB-S"

  private_network {
    private_network_id = scaleway_vpc_private_network.demo.id
    dhcp_config        = true
  }

  depends_on = [scaleway_vpc_gateway_network.demo]
}

resource "scaleway_lb_certificate" "demo" {
  lb_id = scaleway_lb.demo.id
  name  = "application"

  letsencrypt {
    common_name = format("%s.kini.to", scaleway_lb_ip.demo.ip_address)
  }
  depends_on = [scaleway_lb.demo]
}

resource "scaleway_lb_backend" "demo" {
  lb_id            = scaleway_lb.demo.id
  name             = "backend"
  forward_protocol = "http"
  forward_port     = 80
  forward_port_algorithm   = "leastconn"
  ignore_ssl_server_verify = true
  sticky_sessions          = "table"
  server_ips               = data.scaleway_ipam_ip.app.*.address
  health_check_port = 80
  health_check_http {
    uri    = "/"
    code   = 200
    method = "GET"
  }
}

resource "scaleway_lb_frontend" "demo" {
  name            = "frontend"
  lb_id           = scaleway_lb.demo.id
  backend_id      = scaleway_lb_backend.demo.id
  inbound_port    = 443
  certificate_ids = [scaleway_lb_certificate.demo.id]
}

output "access" {
  value = format("https://%s.kini.to", scaleway_lb_ip.demo.ip_address)
}
