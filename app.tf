resource "scaleway_instance_server" "app" {
  count = var.sizing
  name  = format("app-%02d", count.index + 1)
  type  = "DEV1-S"
  image = "ubuntu_jammy"
  private_network {
    pn_id = scaleway_vpc_private_network.demo.id
  }
  user_data = {
    cloud-init = <<-EOT
    #cloud-config
    write_files:
    - content: |
        web:
          port: "80"
          user: myadmin
          pass: scaleway
        db:
          port: "${scaleway_rdb_instance.demo.private_network[0].port}"
          host: "${scaleway_rdb_instance.demo.private_network[0].ip}"
          name: "rdb"
          user: "db_user"
          pass: "${random_password.db.result}"
      path: /tmp/config.yml
    runcmd:
    - mkdir -p /opt/app/
    - mv /tmp/config.yml /opt/app/config.yml
    - curl -sSL -o /opt/app/scw-test-app https://github.com/n-Arno/scw-test-app/releases/download/v1.0/scw-test-app-linux-amd64
    - chmod +x /opt/app/scw-test-app
    - curl -sSL -o /etc/systemd/system/scw-test-app.service https://github.com/n-Arno/scw-test-app/releases/download/v1.0/scw-test-app.service
    - systemctl daemon-reload && systemctl enable --now scw-test-app
    EOT
  }

  depends_on = [scaleway_rdb_instance.demo, random_password.db, scaleway_vpc_gateway_network.demo]
}

data "scaleway_ipam_ip" "app" {
  count = var.sizing
  mac_address = scaleway_instance_server.app[count.index].private_network.0.mac_address
  type        = "ipv4"
}
