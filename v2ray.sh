#!/bin/bash

# Variables
DOMAIN="chinesetexts.duckdns.org"
EMAIL="hoxetok619@pacfut.com"
UUID=$(uuidgen)
V2RAY_PATH="/usr/local/bin/v2ray"
V2RAY_CONFIG_PATH="/usr/local/etc/v2ray/config.json"
CERTBOT_LOG="/var/log/letsencrypt/letsencrypt.log"

# Actualizar el sistema
echo "Actualizando el sistema..."
sudo apt update -y && sudo apt upgrade -y

# Instalar dependencias necesarias
echo "Instalando dependencias..."
sudo apt install -y curl unzip socat cron python3-certbot-nginx jq

#Apagamos los procesos nginx que se acaban de establecer en el puerto 80
sudo systemctl stop nginx

# Instalar V2Ray
echo "Instalando V2Ray..."
wget https://github.com/v2fly/v2ray-core/releases/download/v5.37.0/v2ray-linux-64.zip -O /tmp/v2ray-linux.zip
unzip /tmp/v2ray-linux.zip -d /tmp/v2ray
sudo mv /tmp/v2ray/v2ray /usr/local/bin/
sudo mv /tmp/v2ray/v2ctl /usr/local/bin/
sudo mv /tmp/v2ray/geoip.dat /usr/local/share/v2ray/
sudo mv /tmp/v2ray/geosite.dat /usr/local/share/v2ray/
sudo rm -rf /tmp/v2ray

# Configurar el servicio de V2Ray
echo "Creando archivos de servicio de V2Ray..."
sudo bash -c 'cat << EOF > /etc/systemd/system/v2ray.service
[Unit]
Description=V2Ray Service
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/v2ray run -config /usr/local/etc/v2ray/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF'

# Crear directorios necesarios
sudo mkdir -p /usr/local/etc/v2ray /var/log/v2ray

# Configuración de V2Ray
echo "Configurando V2Ray..."
sudo bash -c 'cat << EOF > /usr/local/etc/v2ray/config.json
{
  "inbounds": [
    {
      "port": 443,
      "listen": "0.0.0.0",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "'$UUID'",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "wsSettings": {
          "path": "/myapp",
          "headers": {
            "Host": "'$DOMAIN'"
          }
        },
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/etc/letsencrypt/live/'$DOMAIN'/fullchain.pem",
              "keyFile": "/etc/letsencrypt/live/'$DOMAIN'/privkey.pem"
            }
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ],
  "log": {
    "loglevel": "warning"
  }
}
EOF'

# Instalar Certbot
echo "Instalando Certbot..."
sudo apt install -y certbot

# Obtener el certificado SSL para el dominio
echo "Solicitando certificado SSL para $DOMAIN..."
sudo certbot certonly --non-interactive --agree-tos --email $EMAIL --standalone -d $DOMAIN

# Configurar la renovación automática del certificado
echo "Configurando la renovación automática del certificado..."
sudo systemctl enable certbot.timer

# Configuración adicional
echo "Configurando firewall (si es necesario)..."
# Abre el puerto 443 para V2Ray
sudo ufw allow 443/tcp

# Activar y arrancar V2Ray
echo "Habilitando y arrancando V2Ray..."
sudo systemctl enable v2ray
sudo systemctl start v2ray

# Verificar el estado de V2Ray
echo "Verificando el estado de V2Ray..."
sudo systemctl status v2ray

echo "V2Ray con Certbot ha sido configurado correctamente."
echo "Por favor, revisa el archivo de configuración de V2Ray en /usr/local/etc/v2ray/config.json"
echo "La configuración del cliente es:"
echo -e '{
  "v": "2",
  "ps": "ChinaBypass",
  "add": "'$DOMAIN'",
  "port": "443",
  "id": "'$UUID'",
  "aid": "0",
  "net": "ws",
  "type": "none",
  "host": "'$DOMAIN'",
  "path": "/myapp",
  "tls": "tls"
}'
echo "El UUID generado es: $UUID"