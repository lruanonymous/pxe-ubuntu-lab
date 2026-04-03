# PXE Boot Ubuntu Server (UEFI, Mac mini, Zero → Interactive Install)

This guide documents how to build a **fully working PXE environment** using:

- macOS (Mac mini)
- dnsmasq (DHCP + TFTP)
- iPXE (`snponly.efi`)
- Python HTTP server
- Ubuntu Server ISO

It supports:
- ✅ Interactive installs (keyboard works)
- ✅ Optional autoinstall (unattended)
- ✅ UEFI-only systems (e.g. Dell Wyse 5070)

---

# 📦 Requirements

- Mac with:
  - Homebrew installed
  - Ethernet connected to PXE network
- Client device (UEFI PXE capable)
- Ubuntu Server ISO (e.g. 24.04)
- Python3

---

# ⚠️ Important Notes

- Disable **Secure Boot** OR use signed iPXE binary
- macOS Internet Sharing may conflict with dnsmasq
- Keyboard may NOT work in iPXE (this is normal)

---

# 🚀 Step 1: Install dnsmasq

```bash
brew install dnsmasq
```

---

# 📁 Step 2: Create Directory Structure

```bash
sudo mkdir -p /private/tftpboot
mkdir -p ~/pxe/http/ubuntu
mkdir -p ~/pxe/http/nocloud
```

---

# 🌐 Step 3: Download iPXE Bootloader

```bash
cd /private/tftpboot
sudo curl -O https://boot.ipxe.org/x86_64-efi/snponly.efi
```

---

# 💿 Step 4: Add Ubuntu ISO

```bash
cp ~/Downloads/ubuntu-24.04-live-server-amd64.iso ~/pxe/http/ubuntu/ubuntu.iso
```

---

# 📂 Step 5: Extract Kernel + Initrd (IMPORTANT)

macOS often cannot mount Linux ISOs reliably.

Use:

```bash
brew install p7zip

cd ~/pxe/http/ubuntu
7z x ubuntu.iso casper/vmlinuz casper/initrd

mv casper/vmlinuz .
mv casper/initrd .
rm -rf casper
```

---

# 🌍 Step 6: Start HTTP Server

```bash
cd ~/pxe/http
python3 -m http.server 8080
```

---

# 🧾 Step 7: Create iPXE Script (Interactive Install)

```bash
nano ~/pxe/http/boot.ipxe
```

```ipxe
#!ipxe
dhcp

set base http://192.168.1.1:8080/ubuntu

echo Booting Ubuntu Installer...

kernel ${base}/vmlinuz ip=dhcp url=${base}/ubuntu.iso ---
initrd ${base}/initrd

boot
```

---

# ⚙️ Step 8: Configure dnsmasq

```bash
nano /opt/homebrew/etc/dnsmasq.conf
```

```ini
interface=en0
bind-interfaces

dhcp-range=192.168.1.50,192.168.1.150,12h
dhcp-option=3,192.168.1.1
dhcp-option=6,8.8.8.8

enable-tftp
tftp-root=/private/tftpboot

dhcp-boot=snponly.efi,,192.168.1.1

log-dhcp
```

---

# 🧪 Step 9: Validate Config

```bash
dnsmasq --test -C /opt/homebrew/etc/dnsmasq.conf
```

---



# 🐛 Step 10: Run dnsmasq (Debug Mode)

```bash
sudo dnsmasq -d -C /opt/homebrew/etc/dnsmasq.conf
```

---

# 🖥️ Step 11: Boot Client

- Set PXE/network boot in BIOS
- Ensure UEFI mode is enabled

---

# 🎯 Expected Behavior

1. Client gets IP via DHCP  
2. Downloads `snponly.efi`  
3. iPXE runs script  
4. Ubuntu installer loads  
5. **Keyboard starts working here**  
6. Install Ubuntu normally  

---

# 🔍 Troubleshooting

## No DHCP logs

```bash
sudo tcpdump -ni en0 port 67 or port 68
```

---

## File not found

```bash
curl http://192.168.1.1:8080/ubuntu/vmlinuz
```

---

## Stuck at "Waiting for cloud-init"

👉 Remove:
- `autoinstall`
- `ds=nocloud`
- `cloud-config-url`

---

# 🤖 Optional: Autoinstall (Unattended)

## boot.ipxe (automated)

```ipxe
#!ipxe
dhcp

set base http://192.168.1.1:8080/ubuntu
set seed http://192.168.1.1:8080/nocloud/

kernel ${base}/vmlinuz ip=dhcp url=${base}/ubuntu.iso autoinstall ds=nocloud-net\;s=${seed} cloud-config-url=/dev/null
initrd ${base}/initrd

boot
```

---

## user-data

```yaml
#cloud-config
autoinstall:
  version: 1
  identity:
    hostname: ubuntu
    username: user
    password: "$6$HASH"
```

---

## meta-data

```yaml
instance-id: iid-local01
local-hostname: ubuntu
```

---

# 🧠 Key Concepts

- **PXE** = initial network boot  
- **TFTP** = delivers bootloader  
- **iPXE** = loads scripts via HTTP  
- **HTTP** = delivers OS files  
- **cloud-init** = automates install  

---

# 🚀 Future Improvements

- Add boot menu (multi-OS)  
- Automate via Ansible  
- Replace Python server with nginx  
- Add HTTPS support  

---

# 🏁 Summary

You now have a:

- Fully reproducible PXE environment  
- UEFI-compatible boot flow  
- Interactive OR automated install capability  

---

# 📎 License

MIT
