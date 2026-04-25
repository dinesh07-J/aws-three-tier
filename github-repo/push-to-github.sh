#!/bin/bash
# ============================================================
#  push-to-github.sh — Run once to push project to GitHub
#  EDIT: YOUR_GITHUB_USERNAME below first!
# ============================================================
YOUR_GITHUB_USERNAME="YOUR_GITHUB_USERNAME"
REPO_NAME="aws-three-tier-uservault"

git init
git branch -M main
git add .
git commit -m "🚀 Initial commit: AWS Three-Tier Architecture (UserVault)

Tier 1: S3 + CloudFront (HTML/CSS/JS frontend)
Tier 2: EC2 + ALB (Node.js Express REST API)
Tier 3: RDS MySQL (schema, triggers, seed data)
CI/CD: GitHub Actions deploy pipeline"

git remote add origin https://github.com/${YOUR_GITHUB_USERNAME}/${REPO_NAME}.git
git push -u origin main

echo ""
echo "✅ Pushed to: https://github.com/${YOUR_GITHUB_USERNAME}/${REPO_NAME}"
echo ""
echo "Next → Add GitHub Secrets (Settings → Secrets → Actions):"
echo "  AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION"
echo "  S3_BUCKET, ALB_DNS, CF_DISTRIBUTION_ID"
echo "  EC2_HOST_A, EC2_HOST_B, EC2_SSH_KEY"
