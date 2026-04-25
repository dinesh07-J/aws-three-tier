#!/bin/bash
# ============================================================
#  deploy-to-s3.sh — Tier 1: Presentation Layer Deployer
#  Run this from your LOCAL machine (not EC2)
#  Requires: AWS CLI installed + configured (aws configure)
# ============================================================

set -e  # Exit on any error

# ── CONFIGURE THESE ───────────────────────────────────────
BUCKET_NAME="my-uservault-frontend"           # Your S3 bucket name
AWS_REGION="ap-south-1"                       # Your AWS region
ALB_DNS="YOUR-ALB-DNS.ap-south-1.elb.amazonaws.com"  # ← Paste ALB URL here

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   Tier 1: Presentation Layer — S3 Deployment    ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ── Step 1: Patch ALB URL into app.js ────────────────────
echo "▶ Step 1: Patching ALB endpoint into app.js..."
sed -i.bak "s|http://localhost:3000|http://${ALB_DNS}|g" app.js
echo "  ✓ app.js updated with: http://${ALB_DNS}"

# ── Step 2: Create S3 bucket ──────────────────────────────
echo ""
echo "▶ Step 2: Creating S3 bucket..."
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$AWS_REGION" \
  --create-bucket-configuration LocationConstraint="$AWS_REGION" 2>/dev/null || echo "  ℹ  Bucket already exists"

# ── Step 3: Disable Block Public Access ──────────────────
echo ""
echo "▶ Step 3: Enabling public access..."
aws s3api delete-public-access-block \
  --bucket "$BUCKET_NAME"

# ── Step 4: Apply bucket policy ──────────────────────────
echo ""
echo "▶ Step 4: Applying public-read bucket policy..."
cat > /tmp/bucket-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "PublicReadGetObject",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::${BUCKET_NAME}/*"
  }]
}
EOF
aws s3api put-bucket-policy \
  --bucket "$BUCKET_NAME" \
  --policy file:///tmp/bucket-policy.json

# ── Step 5: Enable static website hosting ─────────────────
echo ""
echo "▶ Step 5: Enabling static website hosting..."
aws s3 website "s3://${BUCKET_NAME}" \
  --index-document index.html \
  --error-document error.html

# ── Step 6: Upload all files ──────────────────────────────
echo ""
echo "▶ Step 6: Uploading files to S3..."
aws s3 sync . "s3://${BUCKET_NAME}" \
  --exclude "*.sh" \
  --exclude "*.bak" \
  --exclude ".DS_Store" \
  --exclude "README*"

echo "  ✓ Files uploaded!"

# ── Done ──────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║                  ✅  DEPLOYED!                   ║"
echo "╠══════════════════════════════════════════════════╣"
echo "║  S3 URL:   http://${BUCKET_NAME}.s3-website-${AWS_REGION}.amazonaws.com"
echo "║  (Set up CloudFront pointing to this bucket URL)"
echo "╚══════════════════════════════════════════════════╝"
echo ""
