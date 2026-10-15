#!/bin/sh
# AUTOSTART JICHI: /etc/debinet-init.sh memanggil file ini apabila executable.
# Satu proses background agar shell console tetap tersedia.
bash /root/no10-jichi.sh > /root/no10-jichi-startup.log 2>&1 &
