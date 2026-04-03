#!/bin/bash

sudo pkill dnsmasq
pkill -f "python3 -m http.server"
echo "Services stopped."
