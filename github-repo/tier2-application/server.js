// ============================================================
//  server.js — Application Tier (runs on EC2 instances)
//  Node.js + Express REST API
//  Sits between S3 frontend and RDS MySQL database
//
//  Install:  npm install
//  Dev run:  npm run dev
//  Prod run: npm start   OR   pm2 start server.js
// ============================================================

const express = require('express');
const mysql   = require('mysql2/promise');
const cors    = require('cors');
const helmet  = require('helmet');
const morgan  = require('morgan');
const os      = require('os');

const app  = express();
const PORT = process.env.PORT || 3000;

// ── Middleware ────────────────────────────────────────────
app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors({ origin: '*' }));          // Allow S3/CloudFront origin
app.use(express.json());
app.use(morgan('[:date[iso]] :method :url :status - :response-time ms'));

// ── DB Connection Pool ────────────────────────────────────
//    These come from environment variables set on EC2
//    See: setup-ec2.sh for how to export them
const dbConfig = {
  host:               process.env.DB_HOST     || 'localhost',
  port:    parseInt(  process.env.DB_PORT)    || 3306,
  user:               process.env.DB_USER     || 'admin',
  password:           process.env.DB_PASS     || 'password',
  database:           process.env.DB_NAME     || 'appdb',
  waitForConnections: true,
  connectionLimit:    10,
  queueLimit:         0,
};

const pool = mysql.createPool(dbConfig);

// ── DB Status tracker ─────────────────────────────────────
let dbStatus = 'disconnected';
(async () => {
  try {
    const conn = await pool.getConnection();
    await conn.ping();
    conn.release();
    dbStatus = 'connected';
    console.log(`✅ MySQL connected → ${dbConfig.host}:${dbConfig.port}/${dbConfig.database}`);
  } catch (e) {
    dbStatus = 'error';
    console.error('❌ MySQL failed:', e.message);
    console.error('   Check DB_HOST, DB_USER, DB_PASS, DB_NAME environment variables');
  }
})();

// ══════════════════════════════════════════════════════════
//  ROUTES
// ══════════════════════════════════════════════════════════

// ── GET /health — ALB health check endpoint ───────────────
app.get('/health', (_req, res) => {
  res.status(200).json({
    status:   'OK',
    server:   os.hostname(),
    dbStatus,
    uptime:   Math.floor(process.uptime()) + 's',
    memory:   Math.round(process.memoryUsage().heapUsed / 1024 / 1024) + 'MB',
    time:     new Date().toISOString(),
  });
});

// ── GET /api/users — list all users ──────────────────────
app.get('/api/users', async (_req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT id, name, email, department, role, created_at
       FROM users
       ORDER BY created_at DESC`
    );
    res.json({
      success: true,
      count:   rows.length,
      server:  os.hostname(),
      data:    rows,
    });
  } catch (err) {
    console.error('GET /api/users:', err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ── GET /api/users/:id — get single user ─────────────────
app.get('/api/users/:id', async (req, res) => {
  const id = parseInt(req.params.id);
  if (isNaN(id)) return res.status(400).json({ success: false, error: 'Invalid user ID' });

  try {
    const [rows] = await pool.query(
      'SELECT id, name, email, department, role, created_at FROM users WHERE id = ?', [id]
    );
    if (!rows.length)
      return res.status(404).json({ success: false, error: 'User not found' });

    res.json({ success: true, data: rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ── POST /api/users — create new user ────────────────────
app.post('/api/users', async (req, res) => {
  const { name, email, department = '', role = 'viewer' } = req.body;

  // Validate
  if (!name?.trim() || !email?.trim())
    return res.status(400).json({ success: false, error: 'Name and email are required' });

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email))
    return res.status(400).json({ success: false, error: 'Invalid email format' });

  const validRoles = ['admin', 'editor', 'viewer'];
  const safeRole   = validRoles.includes(role) ? role : 'viewer';

  try {
    const [result] = await pool.query(
      'INSERT INTO users (name, email, department, role) VALUES (?, ?, ?, ?)',
      [name.trim(), email.trim().toLowerCase(), department.trim(), safeRole]
    );
    res.status(201).json({
      success: true,
      id:      result.insertId,
      message: `User "${name}" created successfully`,
    });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY')
      return res.status(409).json({ success: false, error: 'Duplicate entry: email already exists' });

    console.error('POST /api/users:', err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ── PUT /api/users/:id — update a user ───────────────────
app.put('/api/users/:id', async (req, res) => {
  const id = parseInt(req.params.id);
  if (isNaN(id)) return res.status(400).json({ success: false, error: 'Invalid user ID' });

  const allowed = ['name', 'email', 'department', 'role'];
  const fields  = [];
  const values  = [];

  for (const key of allowed) {
    if (req.body[key] !== undefined) {
      fields.push(`${key} = ?`);
      values.push(req.body[key]);
    }
  }
  if (!fields.length)
    return res.status(400).json({ success: false, error: 'No valid fields to update' });

  values.push(id);
  try {
    const [result] = await pool.query(
      `UPDATE users SET ${fields.join(', ')} WHERE id = ?`, values
    );
    if (result.affectedRows === 0)
      return res.status(404).json({ success: false, error: 'User not found' });

    res.json({ success: true, message: `User ${id} updated` });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ── DELETE /api/users/:id — delete a user ────────────────
app.delete('/api/users/:id', async (req, res) => {
  const id = parseInt(req.params.id);
  if (isNaN(id)) return res.status(400).json({ success: false, error: 'Invalid user ID' });

  try {
    const [result] = await pool.query('DELETE FROM users WHERE id = ?', [id]);
    if (result.affectedRows === 0)
      return res.status(404).json({ success: false, error: 'User not found' });

    res.json({ success: true, message: `User ${id} deleted` });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ── 404 fallback ──────────────────────────────────────────
app.use((_req, res) => res.status(404).json({ success: false, error: 'Route not found' }));

// ── Start ─────────────────────────────────────────────────
app.listen(PORT, '0.0.0.0', () => {
  console.log('');
  console.log('╔══════════════════════════════════════════╗');
  console.log('║   UserVault — Application Tier (EC2)    ║');
  console.log('╠══════════════════════════════════════════╣');
  console.log(`║  Port:    ${PORT}`);
  console.log(`║  Host:    ${os.hostname()}`);
  console.log(`║  DB:      ${dbConfig.host}`);
  console.log('╚══════════════════════════════════════════╝');
  console.log('');
});
