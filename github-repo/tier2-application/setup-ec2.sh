#!/bin/bash
# ============================================================
#  setup-ec2.sh — Tier 2: Application Layer EC2 Setup
#
#  USAGE — SSH into your EC2 then run:
#    chmod +x setup-ec2.sh
#    sudo ./setup-ec2.sh
#
#  This script installs Node.js, PM2, copies the app,
#  sets environment variables, and starts the server.
# ============================================================

set -e

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   Tier 2: Application Layer — EC2 Setup         ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ── CONFIGURE THESE before running ────────────────────────
DB_HOST="YOUR-RDS-ENDPOINT.ap-south-1.rds.amazonaws.com"
DB_PORT="3306"
DB_USER="admin"
DB_PASS="YourSecurePass123!"
DB_NAME="appdb"
APP_PORT="3000"

# ── Step 1: System update ─────────────────────────────────
echo "▶ Step 1: Updating system packages..."
yum update -y
echo "  ✓ System updated"

# ── Step 2: Install Node.js 18 ────────────────────────────
echo ""
echo "▶ Step 2: Installing Node.js 18..."
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs
echo "  ✓ Node.js $(node --version) installed"
echo "  ✓ NPM $(npm --version) installed"

# ── Step 3: Install PM2 globally ─────────────────────────
echo ""
echo "▶ Step 3: Installing PM2 process manager..."
npm install -g pm2
echo "  ✓ PM2 $(pm2 --version) installed"

# ── Step 4: Install MySQL client (to test RDS) ───────────
echo ""
echo "▶ Step 4: Installing MySQL client..."
yum install -y mysql
echo "  ✓ MySQL client installed"

# ── Step 5: Create app directory ─────────────────────────
echo ""
echo "▶ Step 5: Setting up application directory..."
mkdir -p /home/ec2-user/app
cp server.js   /home/ec2-user/app/
cp package.json /home/ec2-user/app/
chown -R ec2-user:ec2-user /home/ec2-user/app
echo "  ✓ App files copied to /home/ec2-user/app/"

# ── Step 6: Install Node dependencies ────────────────────
echo ""
echo "▶ Step 6: Installing Node.js dependencies..."
cd /home/ec2-user/app
npm install --production
echo "  ✓ Dependencies installed"

# ── Step 7: Set environment variables ────────────────────
echo ""
echo "▶ Step 7: Writing environment variables..."
cat >> /etc/environment <<EOF

# UserVault — Application Tier Environment Variables
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_USER=${DB_USER}
DB_PASS=${DB_PASS}
DB_NAME=${DB_NAME}
PORT=${APP_PORT}
NODE_ENV=production
EOF

# Also export for current session
export DB_HOST DB_PORT DB_USER DB_PASS DB_NAME PORT NODE_ENV=production
echo "  ✓ Environment variables written to /etc/environment"

# ── Step 8: Start with PM2 ───────────────────────────────
echo ""
echo "▶ Step 8: Starting app with PM2..."
cd /home/ec2-user/app

# Load env vars into PM2 context
env $(cat /etc/environment | grep -v '^#' | xargs) \
  pm2 start server.js \
    --name  "uservault" \
    --env   production \
    --log   /home/ec2-user/app/app.log \
    --time

# Save PM2 process list
pm2 save

# Setup PM2 to auto-start on reboot
pm2 startup systemd -u ec2-user --hp /home/ec2-user
echo "  ✓ App started with PM2"

# ── Step 9: Verify ───────────────────────────────────────
echo ""
echo "▶ Step 9: Verifying server is running..."
sleep 3
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${APP_PORT}/health 2>/dev/null || echo "000")

if [ "$STATUS" = "200" ]; then
  echo "  ✓ Health check passed! Server is UP"
  curl -s http://localhost:${APP_PORT}/health | python3 -m json.tool 2>/dev/null || true
else
  echo "  ⚠ Health check returned: $STATUS"
  echo "  → Check logs: pm2 logs uservault"
fi

# ── Done ─────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║              ✅  EC2 SETUP COMPLETE!             ║"
echo "╠══════════════════════════════════════════════════╣"
echo "║  App dir:  /home/ec2-user/app/"
echo "║  Logs:     pm2 logs uservault"
echo "║  Status:   pm2 status"
echo "║  Restart:  pm2 restart uservault"
echo "║  Health:   curl http://localhost:${APP_PORT}/health"
echo "╚══════════════════════════════════════════════════╝"
echo ""
