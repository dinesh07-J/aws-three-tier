#!/bin/bash
# ============================================================
#  setup-rds.sh — Tier 3: Data Layer RDS Setup
#
#  USAGE — Run this FROM your EC2 instance (Tier 2)
#  EC2 can reach RDS via private subnet. Your laptop cannot.
#
#    chmod +x setup-rds.sh
#    ./setup-rds.sh
# ============================================================

set -e

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   Tier 3: Data Layer — RDS MySQL Setup          ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ── CONFIGURE THESE ───────────────────────────────────────
RDS_HOST="YOUR-RDS-ENDPOINT.ap-south-1.rds.amazonaws.com"
RDS_PORT="3306"
RDS_USER="admin"
RDS_PASS="YourSecurePass123!"
RDS_DB="appdb"

# ── Step 1: Check MySQL client is available ───────────────
echo "▶ Step 1: Checking MySQL client..."
if ! command -v mysql &> /dev/null; then
  echo "  Installing MySQL client..."
  sudo yum install -y mysql
fi
echo "  ✓ MySQL client ready"

# ── Step 2: Test RDS connectivity ─────────────────────────
echo ""
echo "▶ Step 2: Testing connection to RDS..."
mysql \
  -h "$RDS_HOST" \
  -P "$RDS_PORT" \
  -u "$RDS_USER" \
  -p"$RDS_PASS" \
  --connect-timeout=10 \
  -e "SELECT 'RDS connection successful!' AS result;" 2>/dev/null

echo "  ✓ Connected to RDS at $RDS_HOST"

# ── Step 3: Run schema.sql ────────────────────────────────
echo ""
echo "▶ Step 3: Creating database schema and seed data..."
mysql \
  -h "$RDS_HOST" \
  -P "$RDS_PORT" \
  -u "$RDS_USER" \
  -p"$RDS_PASS" \
  < schema.sql

echo "  ✓ Schema created and seed data inserted"

# ── Step 4: Verify tables ─────────────────────────────────
echo ""
echo "▶ Step 4: Verifying database..."
mysql \
  -h "$RDS_HOST" \
  -P "$RDS_PORT" \
  -u "$RDS_USER" \
  -p"$RDS_PASS" \
  "$RDS_DB" \
  -e "SHOW TABLES; SELECT COUNT(*) AS total_users FROM users;"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║           ✅  RDS SETUP COMPLETE!                ║"
echo "╠══════════════════════════════════════════════════╣"
echo "║  Host:     $RDS_HOST"
echo "║  Database: $RDS_DB"
echo "║  Tables:   users, audit_log"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "  Next: Set these on your EC2 (Tier 2):"
echo "    export DB_HOST=$RDS_HOST"
echo "    export DB_USER=$RDS_USER"
echo "    export DB_PASS=$RDS_PASS"
echo "    export DB_NAME=$RDS_DB"
echo ""
