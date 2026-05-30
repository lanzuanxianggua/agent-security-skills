# Additional Vulnerability Classes — Quick Reference for Code Auditing

> Supplements `owasp-top10.md`. Covers important vulnerability classes outside the OWASP Top 10.

---

## 1. XML External Entity (XXE) Injection

**Severity: Critical** — file disclosure, SSRF, denial of service, RCE in rare configurations.

**Detection patterns:**
- XML parsed without disabling external entities
- `new DOMParser()`, `DocumentBuilder`, `xml.etree.ElementTree`, `lxml.etree` without safe config
- SOAP endpoints accepting raw XML bodies
- File upload endpoints that parse uploaded XML/SVG/DOCX files
- `Content-Type: application/xml` accepted without parser hardening
- DTD processing enabled by default

```python
# RED FLAG — Python lxml/ElementTree with defaults
from lxml import etree
tree = etree.parse(xml_file)  # Parses external entities by default

# RED FLAG — Java DocumentBuilderFactory defaults
DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
DocumentBuilder db = dbf.newDocumentBuilder();  // XXE-vulnerable

# RED FLAG — Node.js without entity restriction
const parser = new xml2js.Parser();  // May resolve entities depending on config
parser.parseString(xmlInput, callback);
```

**Fix patterns:**

```python
# Python — defusedxml replaces lxml/ElementTree for untrusted input
import defusedxml.ElementTree as ET
tree = ET.parse(xml_file)  # Blocks external entities and DTDs

# Python — lxml with safe configuration
from lxml import etree
parser = etree.XMLParser(
    resolve_entities=False,
    no_network=True,
    dtd_validation=False,
    load_dtd=False,
)
tree = etree.parse(xml_file, parser=parser)
```

```typescript
// Node.js — libxmljs2 with safe defaults
import { parseXml } from 'libxmljs2';
const doc = parseXml(xmlString, {
  noent: false,    // Do not substitute entities
  dtdload: false,  // Do not load external DTD
  dtdattr: false,  // Do not default DTD attributes
  nonet: true,     // Block network access
});

// Node.js — fast-xml-parser (no entity resolution by design)
import { XMLParser } from 'fast-xml-parser';
const parser = new XMLParser();  // Safe: pure JS, no entity expansion
const obj = parser.parse(xmlString);
```

```typescript
// Express — reject XML content type unless expected
app.use((req, res, next) => {
  const ct = req.headers['content-type'] || '';
  if (ct.includes('xml') && !isXmlEndpoint(req.path)) {
    return res.status(415).json({ error: 'XML not accepted' });
  }
  next();
});
```

---

## 2. Server-Side Template Injection (SSTI)

**Severity: Critical** — leads to remote code execution on the server.

**Detection patterns:**
- User input interpolated directly into template strings
- `render_template_string(user_input)` in Flask/Jinja2
- `Twig::createTemplate($userInput)->render()` in PHP
- `ejs.render(userInput)` or `Handlebars.compile(userInput)` with user-controlled source
- Math expression evaluators that reach into object graphs (`__class__`, `__mro__`, `__subclasses__`)
- Template expressions in logs: `{{7*7}}`, `${7*7}`, `<%= 7*7 %>`

```python
# RED FLAG — Jinja2 with user-controlled template source
from jinja2 import Template
template = Template(user_input)  # SSTI: user controls the template
template.render()

# RED FLAG — Flask render_template_string with user data
@app.route('/greet')
def greet():
    name = request.args.get('name', '')
    return render_template_string(f'<h1>Hello {name}</h1>')  # SSTI

# RED FLAG — Tornado with user input in template
self.render(f'<div>{user_content}</div>')
```

```typescript
// RED FLAG — EJS with user-controlled template
import ejs from 'ejs';
const html = ejs.render(req.body.template, data);  // SSTI

// RED FLAG — Handlebars compiling user input
const template = Handlebars.compile(req.query.template);
template(data);  // SSTI
```

**Fix patterns:**

```python
# Python — Jinja2 sandbox: use separate data and template
from jinja2 import Environment, select_autoescape

env = Environment(autoescape=select_autoescape(['html']))
# Template is developer-controlled; only DATA comes from user
template = env.from_string('<h1>Hello {{ name | e }}</h1>')
html = template.render(name=user_name)  # Safe: name is escaped

# Python — Flask: use template files, never string interpolation
@app.route('/greet')
def greet():
    name = request.args.get('name', '')
    return render_template('greet.html', name=name)
# greet.html: <h1>Hello {{ name | escape }}</h1>

# Python — Jinja2 sandbox mode for untrusted templates (last resort)
from jinja2.sandbox import SandboxedEnvironment
sandbox = SandboxedEnvironment()
# Restrict available globals, no __class__, __mro__, etc.
template = sandbox.from_string(user_template)
```

```typescript
// Node.js — never compile user input as templates
import ejs from 'ejs';

// GOOD: developer-controlled template, user data as variables
const html = ejs.render('<h1>Hello <%= name %></h1>', { name: userName });

// NEVER: ejs.render(userControlledString, data)

// Handlebars — use pre-compiled templates, reject dynamic compilation
import Handlebars from 'handlebars';

// GOOD: template is in a file, compiled at startup
const template = Handlebars.compile(fs.readFileSync('template.hbs', 'utf8'));
const html = template({ name: userName });  // userName is auto-escaped

// Input validation: reject template syntax in user input
function rejectTemplateSyntax(input: string): void {
  const sstiPatterns = [/\{\{.*\}\}/, /<%.*%>/, /\$\{.*\}/];
  for (const pattern of sstiPatterns) {
    if (pattern.test(input)) {
      throw new Error('Invalid input: template syntax not allowed');
    }
  }
}
```

---

## 3. Race Conditions & TOCTOU (Time-of-Check to Time-of-Use)

**Severity: Medium to Critical** — data corruption, double-spending, authentication bypass.

**Detection patterns:**
- Check-then-act without locking: `if balance >= amount then deduct`
- File existence check then write: `if (!exists) { write() }`
- Database read-modify-write without transactions
- No mutex/lock on shared mutable state
- `async` handlers that read and write shared state without coordination
- Coupon/promo code redemption without atomic decrement
- Voting/liking without idempotency checks

```python
# RED FLAG — TOCTOU on filesystem
if not os.path.exists(file_path):       # Check
    with open(file_path, 'w') as f:     # Use — race window!
        f.write(content)

# RED FLAG — non-atomic balance check
balance = Account.get_balance(user_id)
if balance >= amount:          # Check
    Account.deduct(user_id, amount)  # Use — another request could deduct between these!
```

```typescript
// RED FLAG — non-atomic coupon redemption
app.post('/api/redeem', async (req, res) => {
  const coupon = await Coupon.findById(code);     // Read
  if (coupon.usesRemaining > 0) {                 // Check
    coupon.usesRemaining -= 1;                    // Modify
    await coupon.save();                          // Write — race window!
  }
});
```

**Fix patterns:**

```python
# Python — atomic filesystem operations
import os, tempfile

# Use O_EXCL for atomic create-if-not-exists
fd = os.open(file_path, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o644)
os.write(fd, content.encode())
os.close(fd)

# Python — database-level atomic operations with row locks
from django.db import transaction

@transaction.atomic
def deduct_balance(user_id, amount):
    # SELECT ... FOR UPDATE locks the row until commit
    account = Account.objects.select_for_update().get(pk=user_id)
    if account.balance < amount:
        raise InsufficientFunds()
    account.balance -= amount
    account.save()
```

```typescript
// Node.js — atomic MongoDB update with condition
await Coupon.updateOne(
  { _id: couponId, usesRemaining: { $gt: 0 } },  // Atomic check + decrement
  { $inc: { usesRemaining: -1 } }
);

// Node.js — Redis atomic decrement for counters
const remaining = await redis.decr('coupon:abc123:remaining');
if (remaining < 0) {
  await redis.incr('coupon:abc123:remaining'); // Rollback
  return res.status(400).json({ error: 'Coupon exhausted' });
}

// Node.js — SQL SELECT FOR UPDATE
await sequelize.transaction(async (txn) => {
  const account = await Account.findByPk(userId, {
    lock: txn.LOCK.UPDATE,  // SELECT ... FOR UPDATE
    transaction: txn,
  });
  if (account.balance < amount) throw new Error('Insufficient funds');
  account.balance -= amount;
  await account.save({ transaction: txn });
});
```

```typescript
// General pattern: idempotency keys for deduplication
app.post('/api/transfer', async (req, res) => {
  const idempotencyKey = req.headers['idempotency-key'];
  if (!idempotencyKey) return res.status(400).json({ error: 'Idempotency key required' });

  const processed = await redis.set(
    `idem:${idempotencyKey}`, '1', 'NX', 'EX', 3600
  );
  if (!processed) {
    return res.json({ message: 'Already processed' });  // Dedup
  }
  // ... safe to process once
});
```

---

## 4. CORS Deep-Dive

**Severity: Medium to High** — credential theft, data exfiltration, API abuse.

**Detection patterns:**
- `Access-Control-Allow-Origin: *` with `Access-Control-Allow-Credentials: true` (browsers block this, but server misalignment signals bugs)
- `Access-Control-Allow-Origin` reflecting the request `Origin` header verbatim
- `Access-Control-Allow-Origin: null` (attackers can send null origin from sandboxed iframes)
- No `Access-Control-Allow-Methods` restriction (allows DELETE, PUT)
- Wildcard subdomain matching: `.example.com` logic that also matches `evil.example.com.attacker.com`
- Preflight responses cached too long or missing `Vary: Origin`

```typescript
// RED FLAG — naive origin reflection
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', req.headers.origin); // Reflects ANY origin
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  next();
});

// RED FLAG — regex bypass
const allowed = /^https?:\/\/.*\.example\.com$/;
// Matches https://evil.example.com.attacker.com because .* is greedy

// RED FLAG — null origin accepted
if (origin === 'null' || origin === undefined) {
  res.setHeader('Access-Control-Allow-Origin', origin);
}
```

**Fix patterns:**

```typescript
// Node.js — strict allowlist with exact match
import cors from 'cors';

const ALLOWED_ORIGINS = new Set([
  'https://app.example.com',
  'https://admin.example.com',
]);

const corsOptions = {
  origin: (origin: string | undefined, callback: (err: Error | null, ok?: boolean) => void) => {
    // Allow server-to-server (no origin) or allowlisted origins only
    if (!origin || ALLOWED_ORIGINS.has(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  maxAge: 600,  // Preflight cache: 10 minutes max
};

app.use(cors(corsOptions));
```

```python
# Python Flask — strict CORS
from flask_cors import CORS

app = Flask(__name__)
CORS(app, origins=[
    'https://app.example.com',
    'https://admin.example.com',
], supports_credentials=True, methods=['GET', 'POST'])
```

```typescript
// Subdomain matching — escape the dot and anchor the regex
function isAllowedSubdomain(origin: string): boolean {
  const url = new URL(origin);
  // Exact match on example.com or *.example.com subdomains
  return url.hostname === 'example.com' ||
    url.hostname.endsWith('.example.com');  // Safe: '.example.com' suffix
  // NEVER: url.hostname.includes('example.com')
}

// Always set Vary: Origin when CORS is dynamic
app.use((req, res, next) => {
  res.setHeader('Vary', 'Origin');
  next();
});
```

---

## 5. IDOR Deep-Dive (Insecure Direct Object Reference)

**Severity: High** — unauthorized data access, enumeration of all records.

**Detection patterns:**
- Sequential integer IDs in URLs: `/api/users/1`, `/api/orders/42`
- No ownership verification on `findById()`, `findOne()`, `get()` calls
- Bulk endpoints accepting arrays of IDs: `/api/orders?ids=1,2,3,4,5`
- API returning different fields depending on the ID without checking the caller
- UUIDs used but leaked via list endpoints without pagination or auth scoping
- File download URLs with predictable paths: `/files/invoices/INV-00001.pdf`
- User-controlled `userId`, `orgId`, or `accountId` in request body overriding session

```typescript
// RED FLAG — no ownership check
app.get('/api/invoices/:id', requireAuth, async (req, res) => {
  const invoice = await Invoice.findById(req.params.id);  // Any authenticated user sees any invoice
  res.json(invoice);
});

// RED FLAG — body overrides session identity
app.put('/api/profile', requireAuth, async (req, res) => {
  await User.update(req.body.userId, req.body);  // userId from body, not session!
});

// RED FLAG — bulk enumeration
app.get('/api/orders', requireAuth, async (req, res) => {
  const ids = req.query.ids.split(',');  // ?ids=1,2,3,...,10000
  const orders = await Order.find({ _id: { $in: ids } });  // Returns all matching
  res.json(orders);  // No ownership filter
});
```

**Fix patterns:**

```typescript
// Always scope queries to the authenticated user
app.get('/api/invoices/:id', requireAuth, async (req, res) => {
  const invoice = await Invoice.findOne({
    _id: req.params.id,
    userId: req.user.id,  // Ownership enforced at DB level
  });
  if (!invoice) return res.status(404).json({ error: 'Not found' });
  res.json(invoice);
});

// Use UUIDs to prevent easy enumeration (defense in depth, NOT a replacement for auth)
import { v4 as uuidv4 } from 'uuid';
const id = uuidv4();  // Non-sequential, hard to guess

// Bulk endpoints — always filter by ownership, cap array size
app.get('/api/orders', requireAuth, async (req, res) => {
  const ids = req.query.ids?.split(',').slice(0, 50) ?? [];  // Cap at 50
  const orders = await Order.find({
    _id: { $in: ids },
    userId: req.user.id,  // Always scope to owner
  });
  res.json(orders);
});

// Never trust client-supplied identity fields
app.put('/api/profile', requireAuth, async (req, res) => {
  const { name, email } = req.body;
  // Use req.user.id from the session/token, NEVER from the body
  await User.update(req.user.id, { name, email });
});

// Multi-tenant: enforce tenantId at the query level
app.get('/api/documents/:id', requireAuth, requireTenant, async (req, res) => {
  const doc = await Document.findOne({
    _id: req.params.id,
    tenantId: req.tenant.id,  // Tenant isolation at DB level
  });
  if (!doc) return res.status(404).json({ error: 'Not found' });
  res.json(doc);
});
```

```python
# Python Django — use get_object_or_404 with ownership filter
from django.shortcuts import get_object_or_404

def get_invoice(request, pk):
    invoice = get_object_or_404(Invoice, pk=pk, user=request.user)
    return JsonResponse(model_to_dict(invoice))
```

---

## 6. Content Security Policy (CSP)

**Severity: Medium** — XSS mitigation, data injection prevention.

**Detection patterns:**
- No `Content-Security-Policy` header at all
- `script-src 'unsafe-inline'` or `script-src 'unsafe-eval'` — negates XSS protection
- `default-src *` — allows loading from any origin
- Missing `object-src 'none'` — Flash/Java applet injection
- Missing `base-uri 'self'` — base tag hijacking
- No `report-uri` or `report-to` — no visibility into violations
- `style-src 'unsafe-inline'` without nonce/hash — style injection attacks

```
// RED FLAG — permissive CSP
Content-Security-Policy: default-src *; script-src * 'unsafe-inline' 'unsafe-eval'

// RED FLAG — missing object-src and base-uri
Content-Security-Policy: default-src 'self'; script-src 'self'
```

**Fix patterns:**

```typescript
// Node.js — strict CSP with nonces
import crypto from 'crypto';

app.use((req, res, next) => {
  const nonce = crypto.randomBytes(16).toString('base64');
  res.locals.cspNonce = nonce;
  res.setHeader('Content-Security-Policy', [
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}'`,       // No unsafe-inline
    "style-src 'self' 'nonce-${nonce}'",
    "img-src 'self' data: https:",
    "font-src 'self'",
    "connect-src 'self' https://api.example.com",
    "object-src 'none'",                          // Block Flash/applets
    "base-uri 'self'",                            // Prevent base tag hijack
    "form-action 'self'",
    "frame-ancestors 'none'",                     // Prevent framing (clickjacking)
    "upgrade-insecure-requests",
    "report-uri /csp-report",                     // Visibility into violations
  ].join('; '));
  next();
});

// In templates, use the nonce
// <script nonce="{{ cspNonce }}">...</script>
```

```python
# Python — Django CSP middleware
# settings.py
CSP_DEFAULT_SRC = ["'self'"]
CSP_SCRIPT_SRC = ["'self'"]           # Add nonces via django-csp nonce feature
CSP_STYLE_SRC = ["'self'"]
CSP_OBJECT_SRC = ["'none'"]
CSP_BASE_URI = ["'self'"]
CSP_FRAME_ANCESTORS = ["'none'"]
CSP_REPORT_URI = "/csp-report/"
CSP_INCLUDE_NONCE_IN = ['script-src', 'style-src']
```

```
// Minimal strict CSP (report-only first to avoid breakage)
Content-Security-Policy-Report-Only: default-src 'self'; script-src 'self'; report-uri /csp-report
// After validation, switch to enforced:
Content-Security-Policy: default-src 'self'; script-src 'self'; report-uri /csp-report
```

---

## 7. Clickjacking (UI Redressing)

**Severity: Medium** — tricking users into unintended actions.

**Detection patterns:**
- No `X-Frame-Options` header
- No `Content-Security-Policy: frame-ancestors` directive
- `X-Frame-Options: ALLOW` or `ALLOW-FROM` (deprecated and unreliable)
- Frame-busting JavaScript only (`if (top !== self) top.location = self.location`) — bypassable
- Sensitive forms (login, payment, admin actions) loadable in iframes
- Missing `SameSite` cookie attribute (frames send cookies cross-origin)

```html
<!-- RED FLAG — frame-busting JS alone is insufficient -->
<script>
  if (top !== self) { top.location = self.location; }
  // Bypass: sandbox="allow-forms" on attacker's iframe blocks JS but allows forms
</script>
```

**Fix patterns:**

```typescript
// Node.js — both headers for maximum browser coverage
app.use((req, res, next) => {
  res.setHeader('X-Frame-Options', 'DENY');              // Legacy browsers
  // CSP frame-ancestors is set in CSP middleware (see CSP section)
  // frame-ancestors 'none' in CSP overrides X-Frame-Options in modern browsers
  next();
});

// Helmet sets both automatically
import helmet from 'helmet';
app.use(helmet.frameguard({ action: 'deny' }));

// For pages that MUST be framed (e.g., widgets), restrict to specific origins
app.use('/embed/*', (req, res, next) => {
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  // CSP: frame-ancestors 'self' https://trusted-embedder.com
  next();
});
```

```python
# Python Django — middleware
MIDDLEWARE = [
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]
X_FRAME_OPTIONS = 'DENY'

# Per-view override for embeddable content
from django.views.decorators.clickjacking import xframe_options_sameorigin

@xframe_options_sameorigin
def embed_widget(request):
    return render(request, 'widget.html')
```

```typescript
// Complement: SameSite cookies prevent frame-based CSRF
app.use(session({
  cookie: {
    sameSite: 'lax',  // or 'strict' for highest security
    httpOnly: true,
    secure: true,
  },
}));
```

---

## 8. WebSocket Security

**Severity: High** — unauthenticated real-time access, cross-site WebSocket hijacking.

**Detection patterns:**
- WebSocket upgrade without authentication check
- `ws://` (unencrypted) in production
- No `Origin` header validation on upgrade request
- WebSocket messages parsed as JSON without validation
- No rate limiting on message frequency
- Session cookie used as sole auth on WebSocket (CSWSH — Cross-Site WebSocket Hijacking)
- Broadcast messages leaking data to unrelated users

```typescript
// RED FLAG — no auth on WebSocket upgrade
const wss = new WebSocket.Server({ port: 8080 });
wss.on('connection', (ws) => {
  // No authentication — anyone can connect
  ws.on('message', (data) => {
    wss.clients.forEach(client => client.send(data)); // Broadcast to all
  });
});

// RED FLAG — no origin validation
const wss = new WebSocket.Server({ noServer: true });
// Accepts connections from any origin including attacker.com
```

**Fix patterns:**

```typescript
import { WebSocketServer, WebSocket } from 'ws';
import { verify } from 'jsonwebtoken';

const ALLOWED_ORIGINS = new Set([
  'https://app.example.com',
  'https://admin.example.com',
]);

const wss = new WebSocketServer({ noServer: true });

// Authenticate on upgrade — NOT on messages
server.on('upgrade', (req, socket, head) => {
  // 1. Validate Origin header
  const origin = req.headers.origin;
  if (!origin || !ALLOWED_ORIGINS.has(origin)) {
    socket.write('HTTP/1.1 403 Forbidden\r\n\r\n');
    socket.destroy();
    return;
  }

  // 2. Authenticate — use token in query or subprotocol, not cookies alone
  const token = new URL(req.url, 'ws://localhost').searchParams.get('token');
  try {
    const decoded = verify(token, process.env.JWT_SECRET);
    req.user = decoded;
  } catch {
    socket.write('HTTP/1.1 401 Unauthorized\r\n\r\n');
    socket.destroy();
    return;
  }

  // 3. Only then upgrade
  wss.handleUpgrade(req, socket, head, (ws) => {
    ws.userId = req.user.userId;
    wss.emit('connection', ws, req);
  });
});

// Validate and sanitize every message
wss.on('connection', (ws, req) => {
  let messageCount = 0;
  const MESSAGE_LIMIT = 60;  // per minute
  const MESSAGE_WINDOW = 60000;

  ws.on('message', (raw) => {
    // Rate limit
    messageCount++;
    if (messageCount > MESSAGE_LIMIT) {
      ws.close(1008, 'Rate limit exceeded');
      return;
    }

    // Validate message structure
    let msg;
    try {
      msg = JSON.parse(raw);
    } catch {
      ws.close(1003, 'Invalid JSON');
      return;
    }

    // Schema validation
    if (!isValidMessage(msg)) {
      ws.close(1003, 'Invalid message format');
      return;
    }

    // Route to user-scoped handler — never broadcast raw
    handleMessage(ws.userId, msg);
  });
});

// Reset rate limit counter periodically
setInterval(() => { /* reset per-connection counters */ }, MESSAGE_WINDOW);
```

```typescript
// Client — always use wss:// and send auth token
const token = getAuthToken();
const ws = new WebSocket(`wss://api.example.com/ws?token=${token}`);
```

---

## 9. GraphQL Security

**Severity: Medium to High** — data exposure, denial of service, unauthorized access.

**Detection patterns:**
- Introspection query enabled in production (`__schema`, `__type` visible)
- No query depth limiting — deeply nested queries cause exponential resolver calls
- No query complexity analysis
- Missing rate limiting on GraphQL endpoint
- Batch queries accepted without limit: `[{"query":...}, {"query":...}, ...]`
- `debug: true` in production Apollo/Graphene config
- Missing authorization on individual resolvers (relying on query-level auth only)
- Aliases used to bypass rate limits: `a1: user(id:1), a2: user(id:2), a3: user(id:3)`
- Default field suggestions leaking schema in error messages

```graphql
# RED FLAG — query depth attack
query {
  user(id: 1) {
    friends {
      friends {
        friends {
          friends {
            friends { id }  # Exponential resolver calls
          }
        }
      }
    }
  }
}

# RED FLAG — alias abuse for enumeration
query {
  u1: user(id: 1) { email }
  u2: user(id: 2) { email }
  u3: user(id: 3) { email }
  # ... 1000 aliases in one request
}
```

**Fix patterns:**

```typescript
// Apollo Server — depth limiting and complexity analysis
import { ApolloServer } from '@apollo/server';
import { depthLimit } from 'graphql-depth-limit';
import { createComplexityLimitRule } from 'graphql-validation-complexity';

const ComplexityLimit = createComplexityLimitRule(1000, {
  onCost: (cost) => { console.log('query cost:', cost); },
});

const server = new ApolloServer({
  typeDefs,
  resolvers,
  validationRules: [
    depthLimit(5),             // Max 5 levels of nesting
    ComplexityLimit,           // Max cost 1000
  ],
  introspection: process.env.NODE_ENV !== 'production',  // Disable in prod
  debug: false,                // No stack traces in production
});
```

```python
# Python Graphene — depth limiting
from graphql import GraphQLSyntaxError
from graphene import Schema

class Query(graphene.ObjectType):
    user = graphene.Field(UserType, id=graphene.Int())

    def resolve_user(self, info, id):
        # ALWAYS check authorization in resolvers, not just at query level
        if not info.context.user.is_authenticated:
            raise Exception('Unauthorized')
        user = User.objects.get(pk=id)
        if user.id != info.context.user.id and not info.context.user.is_admin:
            raise Exception('Forbidden')
        return user

# Depth limiting middleware
class DepthLimitMiddleware:
    def __init__(self, max_depth=5):
        self.max_depth = max_depth

    def resolve(self, next, root, info, **args):
        depth = len(info.path.as_list())
        if depth > self.max_depth:
            raise Exception(f'Query depth exceeds {self.max_depth}')
        return next(root, info, **args)

schema = Schema(query=Query)
result = schema.execute(
    query_string,
    context_value={'user': current_user},
    middleware=[DepthLimitMiddleware(max_depth=5)],
)
```

```typescript
// Rate limiting on the GraphQL endpoint itself
import rateLimit from 'express-rate-limit';

const graphqlLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 60,              // 60 requests per minute
  standardHeaders: true,
  keyGenerator: (req) => req.user?.id ?? req.ip,
});

app.use('/graphql', graphqlLimiter);
```

---

## 10. API Rate Limiting Patterns

**Severity: Medium** — prevents brute force, scraping, denial of service.

**Detection patterns:**
- No rate limiting on login, password reset, or registration endpoints
- No rate limiting on expensive query endpoints (search, reporting)
- Rate limits based only on IP (trivially bypassed with proxy rotation)
- Global rate limit instead of per-endpoint limits
- No rate limiting on API key creation or token issuance
- Fixed-window counters with burst spikes at window boundaries
- Rate limit headers not returned (clients cannot adapt)

**Fix patterns:**

```typescript
// Pattern 1: Token Bucket — steady rate with burst allowance
// Good for: general API endpoints
class TokenBucket {
  private tokens: number;
  private lastRefill: number;

  constructor(
    private capacity: number,    // Max tokens (burst size)
    private refillRate: number,  // Tokens per second
  ) {
    this.tokens = capacity;
    this.lastRefill = Date.now();
  }

  consume(count = 1): boolean {
    this.refill();
    if (this.tokens >= count) {
      this.tokens -= count;
      return true;
    }
    return false;  // Rate limited
  }

  private refill(): void {
    const now = Date.now();
    const elapsed = (now - this.lastRefill) / 1000;
    this.tokens = Math.min(this.capacity, this.tokens + elapsed * this.refillRate);
    this.lastRefill = now;
  }
}
```

```typescript
// Pattern 2: Sliding Window — precise, no boundary spikes
// Good for: login, password reset, sensitive actions
import Redis from 'ioredis';

async function slidingWindowRateLimit(
  key: string,
  limit: number,
  windowSeconds: number,
): Promise<{ allowed: boolean; remaining: number; resetIn: number }> {
  const now = Date.now();
  const windowStart = now - windowSeconds * 1000;

  const pipeline = redis.pipeline();
  pipeline.zremrangebyscore(key, 0, windowStart);   // Remove expired entries
  pipeline.zcard(key);                                // Count current entries
  pipeline.zadd(key, now, `${now}-${Math.random()}`); // Add this request
  pipeline.expire(key, windowSeconds);
  const results = await pipeline.exec();

  const count = results![1][1] as number;
  const allowed = count < limit;
  const remaining = Math.max(0, limit - count - 1);
  const resetIn = windowSeconds;

  if (!allowed) {
    // Remove the entry we just added since request is rejected
    redis.zrem(key, `${now}-${Math.random()}`);
  }

  return { allowed, remaining, resetIn };
}
```

```typescript
// Pattern 3: Per-endpoint tiered limits
import rateLimit from 'express-rate-limit';

const tiers = {
  // Authentication endpoints — strict
  auth: rateLimit({
    windowMs: 15 * 60 * 1000,  // 15 minutes
    max: 5,
    skipSuccessfulRequests: true,  // Only count failures
    message: { error: 'Too many failed attempts' },
  }),

  // Read endpoints — moderate
  read: rateLimit({
    windowMs: 60 * 1000,       // 1 minute
    max: 100,
  }),

  // Write endpoints — stricter
  write: rateLimit({
    windowMs: 60 * 1000,
    max: 30,
  }),

  // Search/reporting — expensive, very strict
  expensive: rateLimit({
    windowMs: 60 * 1000,
    max: 10,
  }),
};

// Apply per-endpoint
app.post('/login', tiers.auth, loginHandler);
app.post('/register', tiers.auth, registerHandler);
app.get('/api/search', tiers.expensive, searchHandler);
app.get('/api/users', tiers.read, listUsers);
app.post('/api/users', tiers.write, createUser);
app.put('/api/users/:id', tiers.write, updateUser);
app.delete('/api/users/:id', tiers.write, deleteUser);
```

```typescript
// Always return rate limit headers for client visibility
app.use((req, res, next) => {
  // express-rate-limit sets these automatically when standardHeaders: true
  // X-RateLimit-Limit: max requests per window
  // X-RateLimit-Remaining: remaining requests
  // X-RateLimit-Reset: window reset time (Unix timestamp)
  next();
});

// Compound key: userId + IP for authenticated users, IP only for anonymous
function rateLimitKey(req: any): string {
  return req.user?.id
    ? `user:${req.user.id}`
    : `ip:${req.ip}`;
}

const compoundLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 60,
  keyGenerator: rateLimitKey,
  standardHeaders: true,
});
```

```python
# Python — Flask-Limiter with per-endpoint tiers
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

limiter = Limiter(app, key_func=get_remote_address, default_limits=[])

@app.route('/login', methods=['POST'])
@limiter.limit('5 per 15 minutes')   # Strict: 5 failed logins per 15 min
def login():
    ...

@app.route('/api/search')
@limiter.limit('10 per minute')       # Expensive queries
def search():
    ...

@app.route('/api/users', methods=['GET'])
@limiter.limit('100 per minute')      # Read
def list_users():
    ...

@app.route('/api/users', methods=['POST'])
@limiter.limit('30 per minute')       # Write
def create_user():
    ...
```

---

## Quick Severity Lookup

| Vulnerability | Typical Severity | Worst Case |
|---|---|---|
| XXE Injection | Critical | File read, SSRF, RCE |
| SSTI | Critical | Remote Code Execution |
| Race Conditions / TOCTOU | Medium–Critical | Double-spending, data corruption |
| CORS Misconfiguration | Medium–High | Credential theft, data exfiltration |
| IDOR | High | Mass data extraction |
| CSP Misconfiguration | Medium | XSS mitigation bypassed |
| Clickjacking | Medium | Unauthorized user actions |
| WebSocket Vulnerabilities | High | Unauthenticated data access, CSWSH |
| GraphQL Vulnerabilities | Medium–High | Data exposure, DoS |
| Missing Rate Limiting | Medium | Brute force, scraping, DoS |
