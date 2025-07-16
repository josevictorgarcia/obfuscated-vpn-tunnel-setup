#!/bin/bash

# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar WireGuard y simple-obfs
sudo apt install wireguard simple-obfs -y

# Generar claves
wg genkey | tee server_private.key | wg pubkey > server_public.key
wg genkey | tee client_private.key | wg pubkey > client_public.key

# Crear directorio de configuración
sudo mkdir -p /etc/wireguard
sudo mv server_private.key server_public.key client_private.key client_public.key /etc/wireguard/

# Configurar wg0.conf
sudo tee /etc/wireguard/wg0.conf > /dev/null <<EOF
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = $(cat /etc/wireguard/server_private.key)
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = $(cat /etc/wireguard/client_public.key)
AllowedIPs = 10.0.0.2/32
EOF

# Activar IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf

# Iniciar WireGuard
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0

# Ejecutar proxy simple-obfs en segundo plano
nohup simple-obfs -s -l 8888 --obfs http > /dev/null 2>&1 &

echo "✅ WireGuard + proxy ofuscado instalados y ejecutándose en el puerto 8888."