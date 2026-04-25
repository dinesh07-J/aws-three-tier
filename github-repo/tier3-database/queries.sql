-- ============================================================
--  queries.sql — Tier 3: Useful Database Queries Reference
--  Connect to RDS from EC2:
--  mysql -h YOUR-RDS-ENDPOINT -u admin -p appdb
-- ============================================================

USE appdb;

-- ── Check all users ───────────────────────────────────────
SELECT id, name, email, department, role, created_at
FROM users
ORDER BY created_at DESC;

-- ── Count users by role ───────────────────────────────────
SELECT role, COUNT(*) AS total
FROM users
GROUP BY role
ORDER BY total DESC;

-- ── Count users by department ─────────────────────────────
SELECT department, COUNT(*) AS total
FROM users
GROUP BY department
ORDER BY total DESC;

-- ── View audit log ────────────────────────────────────────
SELECT * FROM audit_log ORDER BY performed_at DESC LIMIT 20;

-- ── Find user by email ────────────────────────────────────
SELECT * FROM users WHERE email = 'arjun.kumar@example.com';

-- ── Add a user manually ───────────────────────────────────
INSERT INTO users (name, email, department, role)
VALUES ('Test User', 'test@example.com', 'Engineering', 'viewer');

-- ── Update a user's role ──────────────────────────────────
UPDATE users SET role = 'editor' WHERE id = 3;

-- ── Delete a user ─────────────────────────────────────────
DELETE FROM users WHERE id = 99;

-- ── Show table structure ──────────────────────────────────
DESCRIBE users;
DESCRIBE audit_log;

-- ── Show indexes ──────────────────────────────────────────
SHOW INDEX FROM users;

-- ── Show all triggers ─────────────────────────────────────
SHOW TRIGGERS FROM appdb;

-- ── DB size ───────────────────────────────────────────────
SELECT
  table_name,
  ROUND(((data_length + index_length) / 1024), 2) AS size_kb
FROM information_schema.TABLES
WHERE table_schema = 'appdb';

-- ── Active connections ────────────────────────────────────
SHOW STATUS LIKE 'Threads_connected';

-- ── Check RDS version ─────────────────────────────────────
SELECT VERSION() AS mysql_version;
