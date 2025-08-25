#!/bin/sh -e

UUID=$(openssl x509 -in /var/sota/client.pem -noout -subject | sed 's/^subject.*CN=\([a-zA-Z0-9\.\-]*\).*$/\1/')

echo == Device UUID: $UUID
echo == Generating telegraf config

pkey=$(cat /var/sota/sota.toml | grep tls_pkey_path | cut -d\" -f2)
client=$(cat /var/sota/sota.toml | grep tls_clientcert_path | cut -d\" -f2)
ca=$(cat /var/sota/sota.toml | grep tls_cacert_path | cut -d\" -f2)

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
  mount_points = ["/host-root"]

  ## Ignore mount points by filesystem type.
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]

[[outputs.influxdb_v2]]
  urls = ["https://questdb.gavelci.us:8443"]
  content_encoding = "identity"

  tls_ca = "/var/sota/root.crt"
  tls_cert = "/var/sota/client.pem"
  tls_key = "/var/sota/pkey.pem"

## Recommended by QuestDb
[[aggregators.merge]]
  drop_original = true
EOF

echo == Launching telegraf
exec telegraf --config /tmp/telegraf.conf
