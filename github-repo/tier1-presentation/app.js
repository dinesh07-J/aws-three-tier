/* ============================================================
   app.js — Presentation Tier JavaScript
   Runs in the browser after loading from S3.
   Communicates ONLY with the Application Tier (EC2 via ALB).
   ============================================================

   ✅ BEFORE DEPLOYING TO AWS:
      Change API_BASE below to your ALB DNS name:
      e.g. "http://my-alb-12345.ap-south-1.elb.amazonaws.com"

   🖥️  LOCAL DEV: keep it as "http://localhost:3000"
   ============================================================ */

const API_BASE = 'http://localhost:3000';

let allUsers = [];

// ── Boot ──────────────────────────────────────────────────
window.addEventListener('DOMContentLoaded', () => {
  document.getElementById('t-endpoint').textContent = API_BASE;
  checkHealth();
  fetchUsers();
});

// ── Health Check (pings EC2 /health route) ────────────────
async function checkHealth() {
  try {
    const res  = await fetch(`${API_BASE}/health`);
    const data = await res.json();

    document.getElementById('stat-host').textContent   = data.server   || 'EC2';
    document.getElementById('stat-db').textContent     = data.dbStatus === 'connected' ? '● Online' : '⚠ Offline';
    document.getElementById('stat-uptime').textContent = data.uptime   || '—';
    document.getElementById('t-host').textContent      = data.server   || 'connected';
    document.getElementById('t-status').textContent    = '● connected';
    document.getElementById('t-status').style.color    = '#34d399';
  } catch {
    document.getElementById('stat-host').textContent = 'Unreachable';
    document.getElementById('stat-db').textContent   = '● Error';
    document.getElementById('t-status').textContent  = '● disconnected';
    document.getElementById('t-status').style.color  = '#f87171';
  }
}

// ── Fetch all users from EC2 → RDS ───────────────────────
async function fetchUsers() {
  showLoading();
  try {
    const res  = await fetch(`${API_BASE}/api/users`);
    const data = await res.json();
    if (!data.success) throw new Error(data.error);

    allUsers = data.data;
    document.getElementById('stat-total').textContent = allUsers.length;
    renderTable(allUsers);
  } catch (e) {
    renderError('Cannot reach EC2 backend. Check your server is running.');
  }
}

// ── Add user → POST to EC2 → INSERT into RDS ─────────────
async function addUser() {
  const name  = document.getElementById('inp-name').value.trim();
  const email = document.getElementById('inp-email').value.trim();
  const dept  = document.getElementById('inp-dept').value.trim();
  const role  = document.getElementById('inp-role').value;

  if (!name || !email) return showToast('Name and email are required', 'err');
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))
    return showToast('Enter a valid email address', 'err');

  try {
    const res  = await fetch(`${API_BASE}/api/users`, {
      method:  'POST',
      headers: { 'Content-Type': 'application/json' },
      body:    JSON.stringify({ name, email, department: dept, role }),
    });
    const data = await res.json();
    if (!data.success) throw new Error(data.error);

    showToast(`✓ ${name} added to database!`, 'ok');
    document.getElementById('inp-name').value  = '';
    document.getElementById('inp-email').value = '';
    document.getElementById('inp-dept').value  = '';
    fetchUsers();
  } catch (e) {
    const msg = e.message.includes('Duplicate')
      ? 'Email already exists in database'
      : e.message;
    showToast(msg, 'err');
  }
}

// ── Delete user → DELETE to EC2 → DELETE from RDS ────────
async function deleteUser(id, name) {
  if (!confirm(`Delete "${name}" permanently from the database?`)) return;
  try {
    const res  = await fetch(`${API_BASE}/api/users/${id}`, { method: 'DELETE' });
    const data = await res.json();
    if (!data.success) throw new Error(data.error);
    showToast(`✓ ${name} deleted`, 'ok');
    fetchUsers();
  } catch (e) {
    showToast(e.message, 'err');
  }
}

// ── Filter/search locally ─────────────────────────────────
function filterUsers() {
  const q    = document.getElementById('search').value.toLowerCase();
  const role = document.getElementById('filter-role').value;
  const out  = allUsers.filter(u =>
    (u.name.toLowerCase().includes(q) || u.email.toLowerCase().includes(q)) &&
    (role === '' || u.role === role)
  );
  renderTable(out);
}

// ── Render table ──────────────────────────────────────────
function renderTable(users) {
  const wrap = document.getElementById('table-wrap');

  if (!users.length) {
    wrap.innerHTML = `<div class="empty"><div class="ico">📭</div><p>No users found in RDS</p></div>`;
    return;
  }

  const pill = r => {
    const c = { admin:'r-admin', editor:'r-editor', viewer:'r-viewer' };
    return `<span class="role-pill ${c[r]||'r-viewer'}">${r||'viewer'}</span>`;
  };

  const fmt = d => d
    ? new Date(d).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'})
    : '—';

  const rows = users.map((u, i) => `
    <tr style="animation-delay:${i*35}ms">
      <td><span class="id-tag">#${u.id}</span></td>
      <td>
        <div class="u-name">${esc(u.name)}</div>
        <div class="u-email">${esc(u.email)}</div>
      </td>
      <td><span class="u-dept">${esc(u.department||'—')}</span></td>
      <td>${pill(u.role)}</td>
      <td>${fmt(u.created_at)}</td>
      <td><button class="btn-del" onclick="deleteUser(${u.id},'${esc(u.name)}')">Delete</button></td>
    </tr>`).join('');

  wrap.innerHTML = `
    <table>
      <thead><tr>
        <th>ID</th><th>User</th><th>Department</th><th>Role</th><th>Created</th><th>Action</th>
      </tr></thead>
      <tbody>${rows}</tbody>
    </table>`;
}

// ── Helpers ───────────────────────────────────────────────
function showLoading() {
  document.getElementById('table-wrap').innerHTML =
    '<div class="loading"><div class="spinner"></div><span>Fetching from RDS…</span></div>';
}

function renderError(msg) {
  document.getElementById('table-wrap').innerHTML =
    `<div class="empty"><div class="ico">⚠️</div><p style="color:#f87171">${msg}</p></div>`;
}

function showToast(msg, type = 'ok') {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.className   = `show ${type}`;
  clearTimeout(t._t);
  t._t = setTimeout(() => (t.className = ''), 3500);
}

function esc(s) {
  return String(s||'')
    .replace(/&/g,'&amp;').replace(/</g,'&lt;')
    .replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
