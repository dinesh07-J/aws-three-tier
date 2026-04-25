# 🗃️ Tier 3 — Data Layer (RDS MySQL)

This folder contains everything to set up your **MySQL database** on Amazon RDS.
The database lives in a **private subnet** — only reachable from EC2 (Tier 2).

---

## 📁 Files

```
tier3-database/
├── schema.sql      ← Creates DB, tables, triggers, seed data
├── setup-rds.sh    ← Auto-setup script (run from EC2)
├── queries.sql     ← Useful SQL queries reference
└── README.md       ← This file
```

---

## 🗄️ How to Create RDS in AWS Console

### Step 1 — Create DB Subnet Group
```
RDS → Subnet Groups → Create
  Name:    rds-subnet-group
  VPC:     my-3tier-vpc
  Subnets: private-subnet-1a  AND  public-subnet-1b
           (RDS needs at least 2 Availability Zones)
→ Create
```

### Step 2 — Create RDS Instance
```
RDS → Create Database
  Engine:          MySQL 8.0
  Template:        Free tier
  DB identifier:   uservault-db
  Username:        admin
  Password:        YourSecurePass123!

  Instance class:  db.t3.micro
  Storage:         20 GB  (disable autoscaling)

  VPC:             my-3tier-vpc
  Subnet group:    rds-subnet-group
  Public access:   NO  ← Very important!
  Security group:  rds-sg

→ Create Database (takes ~5 min)
```

### Step 3 — Copy the Endpoint
```
RDS → Databases → uservault-db → Connectivity
  Copy: Endpoint = "uservault-db.xxxxx.ap-south-1.rds.amazonaws.com"
```

---

## 🔧 Run the Schema (from EC2)

Copy files to EC2, then:
```bash
# On your LOCAL machine:
scp -i your-key.pem schema.sql setup-rds.sh \
    ec2-user@<EC2-PUBLIC-IP>:/home/ec2-user/

# SSH into EC2:
ssh -i your-key.pem ec2-user@<EC2-PUBLIC-IP>

# Edit setup-rds.sh with your RDS endpoint:
nano setup-rds.sh   # Change RDS_HOST and RDS_PASS

# Run it:
chmod +x setup-rds.sh
./setup-rds.sh
```

### Or run manually step by step:
```bash
# Connect to RDS from EC2:
mysql -h YOUR-RDS-ENDPOINT -u admin -p

# Inside MySQL:
source schema.sql
# OR
mysql -h YOUR-RDS-ENDPOINT -u admin -p < schema.sql
```

---

## 🏛️ Database Schema

### `users` table
| Column     | Type                       | Description        |
|------------|----------------------------|--------------------|
| id         | INT AUTO_INCREMENT PK      | Unique user ID     |
| name       | VARCHAR(100) NOT NULL      | Full name          |
| email      | VARCHAR(150) UNIQUE        | Email address      |
| department | VARCHAR(100)               | Department name    |
| role       | ENUM(admin,editor,viewer)  | Access level       |
| is_active  | TINYINT(1) DEFAULT 1       | Active flag        |
| created_at | TIMESTAMP                  | Auto-set on INSERT |
| updated_at | TIMESTAMP                  | Auto-set on UPDATE |

### `audit_log` table
| Column       | Type         | Description              |
|--------------|--------------|--------------------------|
| id           | INT PK       | Log entry ID             |
| action       | VARCHAR(20)  | INSERT / UPDATE / DELETE |
| table_name   | VARCHAR(50)  | Which table was affected |
| record_id    | INT          | Which row ID changed     |
| details      | TEXT         | Human-readable summary   |
| performed_at | TIMESTAMP    | When it happened         |

### Triggers (auto-run on every data change)
- `trg_users_after_insert` → logs every new user
- `trg_users_after_update` → logs every update
- `trg_users_after_delete` → logs every deletion

---

## 🔒 Security Rules

The RDS security group (`rds-sg`) must have:
```
Inbound Rules:
  Type:       MySQL/Aurora
  Protocol:   TCP
  Port:       3306
  Source:     ec2-sg  ← ONLY from EC2 security group, not 0.0.0.0!
```

This means: **no one can connect to RDS directly from the internet.**
Only EC2 instances inside the same VPC can query the database.

---

## 🔗 How This Tier Works

```
EC2 Instance (Tier 2)
    │
    │  mysql2 connection pool
    │  host:     rds-endpoint.rds.amazonaws.com
    │  port:     3306
    │  database: appdb
    ▼
RDS MySQL (private subnet)
  ├── Table: users
  └── Table: audit_log
```
