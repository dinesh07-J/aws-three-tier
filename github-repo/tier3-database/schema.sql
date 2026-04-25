-- ============================================================
--  schema.sql — Data Tier (RDS MySQL)
--  Run this from EC2 to set up your database:
--
--  mysql -h YOUR-RDS-ENDPOINT -u admin -p < schema.sql
-- ============================================================

-- Create database
CREATE DATABASE IF NOT EXISTS appdb
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE appdb;

-- ── Users Table ───────────────────────────────────────────
DROP TABLE IF EXISTS audit_log;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id           INT           NOT NULL AUTO_INCREMENT,
  name         VARCHAR(100)  NOT NULL,
  email        VARCHAR(150)  NOT NULL,
  department   VARCHAR(100)  DEFAULT '',
  role         ENUM('admin','editor','viewer') NOT NULL DEFAULT 'viewer',
  is_active    TINYINT(1)    NOT NULL DEFAULT 1,
  created_at   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY   (id),
  UNIQUE  KEY   uq_email      (email),
  INDEX         idx_role      (role),
  INDEX         idx_dept      (department),
  INDEX         idx_active    (is_active),
  INDEX         idx_created   (created_at)

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Stores all application users';

-- ── Audit Log Table ───────────────────────────────────────
CREATE TABLE audit_log (
  id           INT           NOT NULL AUTO_INCREMENT,
  action       VARCHAR(20)   NOT NULL COMMENT 'INSERT / UPDATE / DELETE',
  table_name   VARCHAR(50)   NOT NULL,
  record_id    INT,
  details      TEXT,
  performed_at TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY  (id),
  INDEX        idx_action    (action),
  INDEX        idx_record    (record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── Trigger: log INSERT ───────────────────────────────────
DROP TRIGGER IF EXISTS trg_users_after_insert;
DELIMITER $$
CREATE TRIGGER trg_users_after_insert
  AFTER INSERT ON users FOR EACH ROW
BEGIN
  INSERT INTO audit_log (action, table_name, record_id, details)
  VALUES ('INSERT', 'users', NEW.id, CONCAT('Created user: ', NEW.name, ' <', NEW.email, '>'));
END$$
DELIMITER ;

-- ── Trigger: log DELETE ───────────────────────────────────
DROP TRIGGER IF EXISTS trg_users_after_delete;
DELIMITER $$
CREATE TRIGGER trg_users_after_delete
  AFTER DELETE ON users FOR EACH ROW
BEGIN
  INSERT INTO audit_log (action, table_name, record_id, details)
  VALUES ('DELETE', 'users', OLD.id, CONCAT('Deleted user: ', OLD.name, ' <', OLD.email, '>'));
END$$
DELIMITER ;

-- ── Trigger: log UPDATE ───────────────────────────────────
DROP TRIGGER IF EXISTS trg_users_after_update;
DELIMITER $$
CREATE TRIGGER trg_users_after_update
  AFTER UPDATE ON users FOR EACH ROW
BEGIN
  INSERT INTO audit_log (action, table_name, record_id, details)
  VALUES ('UPDATE', 'users', NEW.id, CONCAT('Updated user ID ', NEW.id));
END$$
DELIMITER ;

-- ── Seed Data ─────────────────────────────────────────────
INSERT INTO users (name, email, department, role) VALUES
  ('Arjun Kumar',   'arjun.kumar@example.com',   'Engineering',   'admin'),
  ('Priya Sharma',  'priya.sharma@example.com',  'Product',       'editor'),
  ('Rahul Singh',   'rahul.singh@example.com',   'Engineering',   'viewer'),
  ('Kavya Nair',    'kavya.nair@example.com',    'Design',        'editor'),
  ('Vikram Reddy',  'vikram.reddy@example.com',  'Sales',         'viewer'),
  ('Meena Iyer',    'meena.iyer@example.com',    'HR',            'admin'),
  ('Anil Gupta',    'anil.gupta@example.com',    'Finance',       'viewer'),
  ('Sneha Patel',   'sneha.patel@example.com',   'Marketing',     'editor');

-- ── Verify ────────────────────────────────────────────────
SELECT '✅ Database setup complete!' AS status;
SELECT COUNT(*) AS total_users FROM users;
SELECT id, name, email, department, role, created_at FROM users ORDER BY id;
SELECT * FROM audit_log ORDER BY performed_at;
