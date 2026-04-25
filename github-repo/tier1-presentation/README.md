# 🌐 Tier 1 — Presentation Layer (S3 + CloudFront)

This folder contains everything for the **frontend** of your three-tier app.
Upload these files to AWS S3 and serve them via CloudFront.

---

## 📁 Files

```
tier1-presentation/
├── index.html          ← Main page (HTML structure)
├── app.js              ← All JS logic (talks to EC2 API)
├── css/
│   └── style.css       ← All styles
├── deploy-to-s3.sh     ← One-command AWS deployment
└── README.md           ← This file
```

---

## 🚀 How to Deploy (3 Steps)

### Step 1 — Edit app.js
Open `app.js` and change line 1:
```js
// Change this:
const API_BASE = 'http://localhost:3000';

// To your ALB DNS (from Tier 2 setup):
const API_BASE = 'http://YOUR-ALB-DNS.ap-south-1.elb.amazonaws.com';
```

### Step 2 — Create S3 Bucket in AWS Console
```
S3 → Create Bucket
  Bucket name:          my-uservault-frontend
  Region:               ap-south-1
  Block public access:  UNCHECK all boxes ✓
  → Create bucket

Permissions tab → Bucket Policy → paste:
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::my-uservault-frontend/*"
  }]
}

Properties tab → Static website hosting → Enable
  Index document: index.html
  Error document: error.html
```

### Step 3 — Upload Files
```
S3 → your bucket → Upload
  Add files: index.html, app.js
  Add folder: css/
  → Upload
```

**OR use the deploy script (requires AWS CLI):**
```bash
chmod +x deploy-to-s3.sh
./deploy-to-s3.sh
```

---

## ☁️ CloudFront Setup (Optional but Recommended)

```
CloudFront → Create Distribution
  Origin domain:          [select your S3 website endpoint]
  Viewer protocol policy: Redirect HTTP to HTTPS
  Cache policy:           CachingOptimized
  → Create distribution

Wait ~5 min → Your URL: https://d1abc123.cloudfront.net
```

---

## 🔗 How This Tier Works

```
User's Browser
    │
    ▼ loads HTML/CSS/JS from
 CloudFront CDN ──→ S3 Bucket
    │
    ▼ app.js makes API calls to
 Application Load Balancer (Tier 2)
```

The browser never talks directly to RDS. All data goes through EC2.
