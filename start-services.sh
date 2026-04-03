#!/bin/bash

cd http
python3 -m http.server 8080 &

sudo dnsmasq -d -C dnsmasq/dnsmasq.conf
