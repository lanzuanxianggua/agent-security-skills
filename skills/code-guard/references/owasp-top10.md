# OWASP Top 10 (2021) — Quick Reference for Code Auditing

## A01: Broken Access Control
**Detection patterns:**
- API routes without authentication middleware
- `findById()` without ownership check → IDOR
- Admin UI served without role check
- CORS set to `*` for authenticated endpoints
- Object-level permissions checked only on frontend

**Fix patterns:**
```typescript
// Always verify ownership
app.get('/api/orders/:id', requireAuth, async (req, res) => {
  const order = await Order.findById(req.params.id);
  if (order.userId !== req.user.id) return res.status(403).json({ error: 'Forbidden' });
  res.json(order);
});

// Use RBAC middleware
app.delete('/api/users/:id', requireAuth, requireRole('admin'), handler);
```

## A02: Cryptographic Failures
**Detection patterns:**
- `crypto.createHash('md5')` or `crypto.createHash('sha1')` for passwords
- `http://` URLs for API endpoints with sensitive data
- AES-ECB mode usage
- Hardcoded IV/salt values
- Custom crypto implementations

**Fix patterns:**
```typescript
// Password hashing — use bcrypt/argon2
const hash = await bcrypt.hash(password, 12);

// Encryption — use AES-256-GCM with random IV
const iv = crypto.randomBytes(16);
const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);

// TLS — enforce in config
app.use((req, res, next) => {
  if (req.headers['x-forwarded-proto'] !== 'https') {
    return res.redirect(301, `https://${req.headers.host}${req.url}`);
  }
  next();
});
```

## A03: Injection
**Detection patterns:**
- `db.query(\`SELECT * FROM t WHERE id = ${input}\`)` — SQL injection
- `eval(userInput)` — code injection
- `exec(\`ls ${userInput}\`)` — command injection
- `innerHTML = userInput` — XSS
- `${userInput}` in HTML templates without escaping

**Fix patterns:**
```typescript
// SQL — parameterized queries
db.query('SELECT * FROM users WHERE id = ?', [userId]);

// Commands — use array args, never shell strings
execFile('ls', ['-la', sanitizedPath]);

// HTML — always escape
import { escape } from 'html-escaper';
element.textContent = userInput; // NOT innerHTML

// NoSQL — use operators explicitly
db.users.find({ _id: new ObjectId(userId) }); // NOT { _id: userId }
```

## A04: Insecure Design
**Detection patterns:**
- No rate limiting on login/password reset
- Predictable ID generation (sequential integers)
- Missing input validation layer
- Business logic bypasses (skip payment step)
- No CSRF protection on state-changing requests

**Fix patterns:**
```typescript
// Rate limiting
app.post('/login', rateLimit({ windowMs: 15*60*1000, max: 5 }), handler);

// Non-predictable IDs
import { nanoid } from 'nanoid';
const id = nanoid(21); // NOT auto-increment

// Input validation
import { z } from 'zod';
const schema = z.object({ email: z.string().email(), age: z.number().int().min(0).max(150) });
const data = schema.parse(req.body);
```

## A05: Security Misconfiguration
**Detection patterns:**
- `app.run(debug=True)` in production
- Default credentials (`admin/admin`)
- Missing security headers
- Directory listing enabled
- Stack traces in error responses

**Fix patterns:**
```typescript
// Security headers
import helmet from 'helmet';
app.use(helmet());

// Hide stack traces
app.use((err, req, res, next) => {
  logger.error(err);
  res.status(500).json({ error: 'Internal server error' }); // No stack trace
});

// Production config
app.set('env', 'production');
app.disable('x-powered-by');
```

## A06: Vulnerable Components
**Detection patterns:**
- `npm audit` shows high/critical CVEs
- Unpinned versions (`"^1.0.0"` in production)
- Abandoned packages (no updates 2+ years)
- `package-lock.json` not committed
- Dev dependencies in production image

**Fix patterns:**
```bash
# Audit and fix
npm audit --fix

# Pin versions for production
npm shrinkwrap

# Check for abandoned packages
npx npcheck
```

## A07: Auth Failures
**Detection patterns:**
- Passwords stored in plaintext or reversible encryption
- Session IDs in URLs
- No session expiration
- Tokens without expiration
- Weak password requirements

**Fix patterns:**
```typescript
// Session config
app.use(session({
  secret: process.env.SESSION_SECRET,
  cookie: { httpOnly: true, secure: true, maxAge: 3600000 },
  resave: false,
  saveUninitialized: false
}));

// JWT with expiration
const token = jwt.sign({ userId }, secret, { expiresIn: '1h' });

// Password strength
app.post('/register', (req, res) => {
  if (!passwordSchema.validate(req.body.password)) {
    return res.status(400).json({ error: 'Password too weak' });
  }
});
```

## A08: Data Integrity Failures
**Detection patterns:**
- No Subresource Integrity on CDN scripts
- Unverified CI/CD pipeline inputs
- Unsafe deserialization (`JSON.parse` on untrusted data without validation)
- No integrity check on downloaded updates
- Auto-update without signature verification

## A09: Logging Failures
**Detection patterns:**
- No logging for failed login attempts
- Passwords/PII in log output
- No centralized log collection
- Missing audit trail for data changes
- No alerting for suspicious patterns

**Fix patterns:**
```typescript
// Structured logging (no secrets)
logger.info('Login attempt', { email, ip: req.ip, success: false });

// Audit trail
logger.audit('Data modified', { userId, resource, action: 'update', timestamp: Date.now() });

// Redact sensitive fields
const redacted = redactPII(user, ['ssn', 'creditCard', 'password']);
```

## A10: SSRF
**Detection patterns:**
- User-controlled URL in `fetch()` / `http.get()`
- Webhook URLs without validation
- Image/file upload from URL without allowlist
- Internal API endpoints exposed via proxy
- Cloud metadata URLs accessible (`169.254.169.254`)

**Fix patterns:**
```typescript
import { URL } from 'url';

const ALLOWED_HOSTS = ['api.example.com', 'cdn.example.com'];

function safeFetch(userUrl: string) {
  const parsed = new URL(userUrl);
  if (!ALLOWED_HOSTS.includes(parsed.hostname)) {
    throw new Error('Host not allowed');
  }
  if (parsed.hostname === '169.254.169.254' || parsed.hostname.startsWith('10.')) {
    throw new Error('Internal addresses not allowed');
  }
  return fetch(userUrl);
}
```
