#!/bin/bash

# ==============================
# Auto WireGuard VPN Server Setup for 50 MikroTik Clients
# ==============================

WG_IF="wg0"
WG_PORT=51820
WG_DIR="/etc/wireguard"
WG_CONF="$WG_DIR/$WG_IF.conf"
SERVER_PRIV="$WG_DIR/server_private.key"
SERVER_PUB="$WG_DIR/server_public.key"
SERVER_IP="10.100.0.1/24"

# Step 1: Install WireGuard
apt update && apt install -y wireguard qrencode

# Step 2: Create Server Keys
umask 077
mkdir -p $WG_DIR
wg genkey | tee $SERVER_PRIV | wg pubkey > $SERVER_PUB

# Step 3: Start Building Config
cat > $WG_CONF <<EOF
[Interface]
Address = $SERVER_IP
ListenPort = $WG_PORT
PrivateKey = $(cat $SERVER_PRIV)
EOF

# Step 4: Generate Peers
for i in $(seq 2 51); do
  CLIENT_PRIV="$WG_DIR/client${i}_private.key"
  CLIENT_PUB="$WG_DIR/client${i}_public.key"
  CLIENT_IP="10.100.0.$i"

  wg genkey | tee $CLIENT_PRIV | wg pubkey > $CLIENT_PUB

  cat >> $WG_CONF <<EOF

[Peer]
PublicKey = $(cat $CLIENT_PUB)
AllowedIPs = $CLIENT_IP/32
EOF

  echo "# --- MikroTik-$i ---"
  echo "PublicKey: $(cat $SERVER_PUB)"
  echo "ClientPrivateKey: $(cat $CLIENT_PRIV)"
  echo "ClientIP: $CLIENT_IP"
  echo ""
done

# Step 5: Enable and Start WireGuard
systemctl enable wg-quick@$WG_IF
systemctl start wg-quick@$WG_IF

# Step 6: Show Server Public Key
clear
echo "✅ WireGuard VPN Server is ready."
echo "Server Public Key: $(cat $SERVER_PUB)"
echo "Server Tunnel IP: 10.100.0.1/24"
echo "Port: $WG_PORT"
