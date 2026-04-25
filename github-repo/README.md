# 🏗️ AWS Three-Tier Architecture — UserVault

![AWS](https://img.shields.io/badge/AWS-Cloud-orange?logo=amazon-aws&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-18.x-green?logo=node.js&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-8.0-blue?logo=mysql&logoColor=white)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen)

A production-ready three-tier web application on AWS — S3, EC2, RDS, CloudFront, ALB.

## Architecture
```
Internet → CloudFront → S3 (Tier 1: Presentation)
                            ↓ API calls
                       ALB → EC2 x2 (Tier 2: Application)
                                ↓ MySQL
                           RDS (Tier 3: Data)
```

## Project Structure
```
aws-three-tier-uservault/
├── tier1-presentation/   ← Upload to S3
│   ├── index.html
│   ├── app.js
│   └── css/style.css
├── tier2-application/    ← Run on EC2
│   ├── server.js
│   └── package.json
├── tier3-database/       ← Run on RDS
│   └── schema.sql
└── .github/workflows/deploy.yml
```

## Deploy Order
1. Create RDS → run `tier3-database/setup-rds.sh`
2. Launch EC2 x2 → run `tier2-application/setup-ec2.sh`
3. Create ALB → target both EC2s
4. Upload to S3 → run `tier1-presentation/deploy-to-s3.sh`

## API Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /health | ALB health check |
| GET | /api/users | List all users |
| POST | /api/users | Create user |
| PUT | /api/users/:id | Update user |
| DELETE | /api/users/:id | Delete user |

## License
MIT © 2025
