#!/bin/bash
# NOMOR 5/6/7: short 1800, long 43200, kugisaki fixed .99
set -e
[ -f /etc/dhcp/dhcpd.conf ] || bash /root/dhcp-base.sh
MAC_INO="02:42:74:4d:20:00"  # DIVERIFIKASI dari ip link dan tcpdump
MAC_KUSAKABE="02:42:e6:2b:ee:00"
MAC_MIWA="02:42:50:8b:4c:00"
MAC_KUGISAKI="02:42:38:7e:bc:00"
cat > /etc/dhcp/net3.conf <<EOF
class "short" {
  match if substring(hardware, 1, 6) = ${MAC_INO}
        or substring(hardware, 1, 6) = ${MAC_KUSAKABE};
  default-lease-time 1800;
  max-lease-time 1800;
}
class "long" {
  match if substring(hardware, 1, 6) = ${MAC_MIWA};
  default-lease-time 43200;
  max-lease-time 43200;
}
subnet 192.222.3.0 netmask 255.255.255.0 {
  option subnet-mask 255.255.255.0;
  option routers 192.222.3.1;
  option broadcast-address 192.222.3.255;
  option domain-name-servers 192.222.1.2, 192.222.1.3;
  option domain-search "K22.com";
  option domain-name "K22.com";
  pool {
    allow members of "short";
    range 192.222.3.10 192.222.3.89;
  }
  pool {
    allow members of "long";
    range 192.222.3.100 192.222.3.199;
  }
  host kugisaki {
    hardware ethernet ${MAC_KUGISAKI};
    fixed-address 192.222.3.99;
  }
}
EOF
bash /root/dhcp-restart.sh
