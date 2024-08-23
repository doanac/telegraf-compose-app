#!/bin/sh -e

UUID=$(openssl x509 -in /var/sota/client.pem -noout -subject | sed 's/^subject.*CN=\([a-zA-Z0-9\.\-]*\).*$/\1/')

echo == Device UUID: $UUID
echo == Generating telegraf config

cat >/tmp/telegraf.conf <<EOF
[global_tags]
  uuid = "${UUID}"

[agent]
  interval = 20

[[inputs.mem]]

[[inputs.cpu]]
totalcpu = true
percpu = false

[[inputs.disk]]
  ## By default stats will be gathered for all mount points.
  ## Set mount_points will restrict the stats to only the specified mount points.
  mount_points = ["/"]

  ## Ignore mount points by filesystem type.
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]

[[outputs.influxdb_v2]]
  urls = ["https://influx.andy.io:8443"]
  organization = "fio"
  bucket = "fio"

  tls_ca = "/var/sota/root.crt"
  tls_cert = "/var/sota/client.pem"
  tls_key = "/var/sota/pkey.pem"
EOF

echo == Launching telegraf
exec telegraf --config /tmp/telegraf.conf
