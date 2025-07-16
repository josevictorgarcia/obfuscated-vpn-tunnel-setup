#!/bin/bash

# ACTUALIZAR SISTEMA
sudo apt update && sudo apt upgrade -y

# INSTALAR Shadowsocks-libev y simple-obfs
sudo apt install shadowsocks-libev simple-obfs -y

# CREAR CONFIGURACIÓN
sudo tee /etc/shadowsocks-libev/config.json > /dev/null <<EOF
{
    "server":"0.0.0.0",
    "server_port":8888,
    "local_port":1080,
    "password":"tuseguro123",
    "timeout":300,
    "method":"aes-256-gcm",
    "plugin":"obfs-server",
    "plugin_opts":"obfs=http"
}
EOF

# HABILITAR E INICIAR EL SERVICIO
sudo systemctl enable shadowsocks-libev
sudo systemctl restart shadowsocks-libev

echo "✅ Shadowsocks + simple-obfs están funcionando en el puerto 8888"