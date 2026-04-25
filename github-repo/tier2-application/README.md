# ⚙️ Tier 2 — Application Layer (EC2 + Node.js)

This folder contains the **backend API server** that runs on your EC2 instances.
It receives requests from the S3 frontend (via ALB) and queries the RDS database.

---

## 📁 Files

```
tier2-application/
├── server.js        ← Node.js Express REST API (all endpoints)
├── package.json     ← Node.js dependencies
├── setup-ec2.sh     ← Full EC2 auto-install script
└── README.md        ← This file
```

---

## 🔌 API Endpoints

| Method | Endpoint         | Description              |
|--------|-----------------|--------------------------|
| GET    | /health          | ALB health check         |
| GET    | /api/users       | Get all users from RDS   |
| GET    | /api/users/:id   | Get one user by ID       |
| POST   | /api/users       | Add new user to RDS      |
| PUT    | /api/users/:id   | Update user in RDS       |
| DELETE | /api/users/:id   | Delete user from RDS     |

---

## 🖥️ How to Deploy on EC2

### Step 1 — Edit setup-ec2.sh
Open `setup-ec2.sh` and fill in your RDS details:
```bash
DB_HOST="your-rds.ap-south-1.rds.amazonaws.com"
DB_PASS="YourSecurePassword"
```

### Step 2 — Copy files to EC2
```bash
# From your LOCAL machine:
scp -i your-key.pem server.js package.json setup-ec2.sh \
    ec2-user@<EC2-PUBLIC-IP>:/home/ec2-user/
```

### Step 3 — SSH into EC2 and run setup
```bash
# SSH into EC2:
ssh -i your-key.pem ec2-user@<EC2-PUBLIC-IP>

# Run the setup script:
chmod +x setup-ec2.sh
sudo ./setup-ec2.sh
```

The script automatically:
- Installs Node.js 18
- Installs PM2 (keeps app alive after reboot)
- Installs all npm packages
- Sets DB environment variables
- Starts the server
- Verifies it's running

### Step 4 — Test the API
```bash
# On the EC2 instance:
curl http://localhost:3000/health
curl http://localhost:3000/api/users

# From anywhere (using EC2 public IP):
curl http://<EC2-PUBLIC-IP>:3000/health
```

---

## 🔧 Useful PM2 Commands (on EC2)

```bash
pm2 status               # Check if app is running
pm2 logs uservault       # View real-time logs
pm2 restart uservault    # Restart the app
pm2 stop uservault       # Stop the app
pm2 delete uservault     # Remove from PM2
```

---

## 📦 NPM Packages Used

| Package  | Purpose                        |
|----------|--------------------------------|
| express  | Web framework / routing        |
| mysql2   | MySQL database driver          |
| cors     | Allow cross-origin from S3     |
| helmet   | HTTP security headers          |
| morgan   | Request logging                |

---

## 🔗 How This Tier Works

```
ALB (Load Balancer)
    │
    ├──▶ EC2 Instance A (server.js on port 3000)
    │         │
    └──▶ EC2 Instance B (server.js on port 3000)
              │
              ▼
         RDS MySQL (Tier 3) — private subnet
```

**Repeat the setup on both EC2 instances for high availability.**
