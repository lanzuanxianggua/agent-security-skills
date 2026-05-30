## Sample Code Guard Audit Report

**Scope:** `src/api/users.ts`, `src/routes/auth.ts`, `config/production.ts`
**Lines Audited:** 247
**Total Findings:** 4 (Critical: 2, High: 1, Medium: 1)

---

### 🔴 Critical Findings

#### CG-001: SQL Injection in User Search
- **Category:** A03-Injection
- **Location:** `src/api/users.ts:42`
- **Description:** User input `req.query.name` is directly interpolated into SQL query, allowing attackers to execute arbitrary SQL commands.
- **Exploitability:** Trivial — single HTTP request
- **Fix:**
  ```typescript
  // BEFORE (vulnerable)
  db.query(`SELECT * FROM users WHERE name LIKE '%${req.query.name}%'`)

  // AFTER (secure)
  db.query('SELECT * FROM users WHERE name LIKE ?', [`%${req.query.name}%`])
  ```

#### SEC-001: Hardcoded AWS Access Key
- **Type:** AWS Access Key
- **Location:** `config/production.ts:12`
- **Confidence:** High
- **Fix:** Rotate immediately. Move to environment variable `process.env.AWS_ACCESS_KEY_ID`.

---

### 🟠 High Findings

#### CG-002: Missing Authentication on Admin Endpoints
- **Category:** A01-Broken Access Control
- **Location:** `src/routes/admin.ts:15-28`
- **Description:** Admin endpoints (`/admin/users`, `/admin/settings`) have no authentication middleware. Any unauthenticated user can access admin functionality.
- **Fix:**
  ```typescript
  // Add auth middleware to admin routes
  app.use('/admin', requireAuth, requireRole('admin'))
  ```

---

### 🟡 Medium Findings

#### CG-003: Missing Rate Limiting on Login
- **Category:** A07-Auth Failures
- **Location:** `src/routes/auth.ts:45`
- **Description:** Login endpoint has no rate limiting, allowing brute-force attacks.
- **Fix:**
  ```typescript
  import rateLimit from 'express-rate-limit'
  app.post('/login', rateLimit({ windowMs: 15*60*1000, max: 5 }), loginHandler)
  ```

---

### Summary

| Severity | Count |
|----------|-------|
| 🔴 Critical | 2 |
| 🟠 High | 1 |
| 🟡 Medium | 1 |
| 🟢 Low | 0 |

**Risk Score:** 28/100 (Grade: D)
**Verdict:** DO NOT MERGE — fix critical and high findings before deploying
