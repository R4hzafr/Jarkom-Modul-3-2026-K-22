#!/bin/bash
# NOMOR 4 (+opsi NOMOR 7): dua pool dengan class berdasarkan MAC.
set -e
[ -f /etc/dhcp/dhcpd.conf ] || bash /root/dhcp-base.sh
MAC_ITADORI="02:42:d5:d6:14:00"
MAC_FUSHIGURO="02:42:ad:10:64:00"
MAC_ZENIN="02:42:af:0b:23:00"
MAC_OKKOTSU="02:42:e3:7b:65:00"
cat > /etc/dhcp/net2.conf <<EOF
class "pool1" {
  match if substring(hardware, 1, 6) = ${MAC_ITADORI}
        or substring(hardware, 1, 6) = ${MAC_FUSHIGURO};
}
class "pool2" {
  match if substring(hardware, 1, 6) = ${MAC_ZENIN}
        or substring(hardware, 1, 6) = ${MAC_OKKOTSU};
}
subnet 192.222.2.0 netmask 255.255.255.0 {
  option subnet-mask 255.255.255.0;
  option routers 192.222.2.1;
  option broadcast-address 192.222.2.255;
  option domain-name-servers 192.222.1.2, 192.222.1.3;
  option domain-search "K22.com";
  option domain-name "K22.com";
  pool {
    allow members of "pool1";
    range 192.222.2.10 192.222.2.35;
  }
  pool {
    allow members of "pool2";
    range 192.222.2.70 192.222.2.95;
  }
}
EOF
bash /root/dhcp-restart.sh
