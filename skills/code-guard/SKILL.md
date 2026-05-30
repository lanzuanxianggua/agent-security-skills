---
name: code-guard
description: "AI-powered code security audit skill. Scans for OWASP Top 10 vulnerabilities, leaked secrets, insecure dependencies, and compliance violations. Outputs structured findings with severity ratings and fix suggestions."
category: security
priority: critical
tokenEstimate: 1200
tags: [security, owasp, audit, vulnerability, secrets, compliance, sast]
---

# Code Guard — AI Code Security Audit

<default_to_action>
When auditing code for security issues:
1. SCAN systematically across all 10 OWASP categories + secrets + dependencies
2. CLASSIFY severity: 🔴 Critical (exploitable) → 🟠 High (easily exploitable) → 🟡 Medium (conditional) → 🟢 Low (best practice) → 💡 Info
3. PROVIDE fixes: Every finding MUST include a concrete code fix, not just a description
4. PRIORITIZE by exploitability: authentication bypasses > injection > misconfig > info leaks
5. VERIFY fixes: Suggested fix must not introduce new vulnerabilities

**Quick Audit Checklist:**
- Injection: SQL, NoSQL, OS command, LDAP, XPath?
- Auth: Broken authentication, session management?
- Data: Sensitive data exposure, crypto misuse?
- Access: Missing authorization checks, IDOR?
- Config: Security headers, CORS, rate limiting?
- Secrets: Hardcoded keys, tokens, passwords in code?
- Dependencies: Known CVEs, outdated packages?
- Input: Missing validation, unsafe deserialization?

**Critical Success Factors:**
- Every finding needs a fix, not just a warning
- False positive rate must stay under 10%
- Audit < 500 lines per pass for accuracy
- Check both the code AND its configuration
</default_to_action>

## When to Use

- Before merging PRs that touch auth, payments, user data, or APIs
- When setting up a new project's security baseline
- During security reviews and penetration test preparation
- When adding dependencies or upgrading packages
- Before deploying to production
- When compliance audit is required (GDPR, HIPAA, PCI-DSS, SOC 2)

## Audit Workflow

### Phase 1: Surface Scan (Quick Pass)
1. Grep for hardcoded secrets, API keys, tokens, passwords
2. Check for SQL string interpolation / template literals in queries
3. Scan for `eval()`, `exec()`, `system()`, `subprocess` with user input
4. Find missing authentication/authorization middleware
5. Check for unsafe deserialization patterns
6. Identify disabled or misconfigured security headers

### Phase 2: Deep Analysis (Full Audit)
1. Trace user input from entry points to data stores (input flow analysis)
2. Check authentication flows for session fixation, weak tokens
3. Verify authorization at every data access point (IDOR checks)
4. Analyze cryptographic operations for weak algorithms
5. Review error handling for information leakage
6. Check file operations for path traversal

### Phase 3: Dependency & Config Audit
1. Audit dependency versions against known CVE databases
2. Check package-lock / yarn.lock for transitive vulnerabilities
3. Review Docker/security configuration
4. Verify CORS, CSP, and security headers
5. Check logging for sensitive data exposure

## OWASP Top 10 Detection Patterns

### A01 — Broken Access Control
```
RED FLAGS:
- Routes without auth middleware
- Direct object references without ownership checks
- Role checks done client-side only
- Admin endpoints without role verification
- API endpoints returning data beyond user scope
```

### A02 — Cryptographic Failures
```
RED FLAGS:
- HTTP used for sensitive data传输
- Weak hash algorithms (MD5, SHA1) for passwords
- Hardcoded encryption keys
- Missing TLS certificate verification
- Sensitive data stored in plaintext
```

### A03 — Injection
```
RED FLAGS:
- String concatenation in SQL/NoSQL queries
- eval/exec with user-controlled input
- Unsanitized input in HTML templates (XSS)
- Command injection via user input in shell commands
- LDAP/XPath queries built from user input
```

### A04 — Insecure Design
```
RED FLAGS:
- No rate limiting on auth endpoints
- No account lockout after failed attempts
- Predictable resource IDs (sequential)
- Missing input validation layer
- Business logic flaws in multi-step flows
```

### A05 — Security Misconfiguration
```
RED FLAGS:
- Debug mode enabled in production
- Default credentials unchanged
- Unnecessary services/ports enabled
- Missing security headers (CSP, X-Frame-Options)
- Verbose error messages exposed to users
```

### A06 — Vulnerable & Outdated Components
```
RED FLAGS:
- Dependencies with known CVEs
- Unpinned dependency versions
- Abandoned packages (no updates in 2+ years)
- Transitive dependency vulnerabilities
- Optional dev dependencies in production bundle
```

### A07 — Auth & Session Failures
```
RED FLAGS:
- Weak password policies
- Session IDs in URLs
- Missing session expiration
- Tokens without expiration/rotation
- Credentials transmitted over HTTP
```

### A08 — Software & Data Integrity Failures
```
RED FLAGS:
- Unverified CI/CD pipeline scripts
- No integrity checks on external data
- Unsafe deserialization of untrusted data
- Missing Subresource Integrity (SRI) for CDNs
- Unsigned deployments or releases
```

### A09 — Security Logging & Monitoring Failures
```
RED FLAGS:
- No logging for auth failures
- Sensitive data in log output
- Missing audit trail for data modifications
- No alerting on suspicious activity
- Logs not centralized or searchable
```

### A10 — Server-Side Request Forgery (SSRF)
```
RED FLAGS:
- User-controlled URLs fetched server-side
- No allowlist for outbound requests
- Internal service URLs constructable from user input
- Missing validation on redirect chains
- Cloud metadata endpoints accessible
```

## Secret Detection Patterns

Scan for these patterns in all source files:

| Pattern | Regex Hint | Risk |
|---------|-----------|------|
| AWS Access Key | `AKIA[0-9A-Z]{16}` | Critical |
| AWS Secret Key | Base64 40-char string near AWS key | Critical |
| GitHub Token | `gh[ps]_[A-Za-z0-9_]{36,}` | Critical |
| Private SSH Key | `BEGIN (RSA\|EC\|OPENSSH) PRIVATE KEY` | Critical |
| Generic API Key | `[Aa]pi[_-]?[Kk]ey\s*[:=]\s*['"][^'"]+['"]` | High |
| Database URL | `(mysql\|postgres\|mongodb)://[^@\s]+@` | High |
| JWT Secret | `[Jj]wt[_-]?[Ss]ecret\s*[:=]\s*['"][^'"]+['"]` | Critical |
| Encryption Key | `[Ee]ncrypt(ion)?[_-]?[Kk]ey\s*[:=]\s*['"][^'"]+['"]` | Critical |
| Password in Config | `[Pp]ass(word)?\s*[:=]\s*['"][^'"]+['"]` | High |
| OAuth Secret | `[Cc]lient[_-]?[Ss]ecret\s*[:=]\s*['"][^'"]+['"]` | Critical |

## Compliance Check Frameworks

### GDPR
- Personal data encryption at rest and in transit
- Right to deletion (data erasure capability)
- Data processing consent tracking
- Data breach notification mechanism
- Privacy by design in data flows

### HIPAA
- PHI encryption requirements
- Access control and audit logs
- Minimum necessary access principle
- Business associate agreement checks
- Breach notification procedures

### PCI-DSS
- Cardholder data encryption
- Network segmentation
- Access control requirements
- Regular security testing
- Logging and monitoring

### SOC 2
- Security control verification
- Availability monitoring
- Processing integrity checks
- Confidentiality controls
- Privacy practices

## Findings Report Format

Every audit MUST produce structured findings:

```markdown
## Security Audit Report

**Scope:** [files/modules scanned]
**Date:** [ISO date]
**Lines Audited:** [count]
**Total Findings:** [count] (Critical: N, High: N, Medium: N, Low: N)

### 🔴 Critical Findings

#### CG-001: SQL Injection in User Search
- **Category:** A03-Injection
- **Location:** `src/api/users.ts:42`
- **Description:** User input `req.query.name` is directly interpolated into SQL query
- **Exploitability:** Trivial — single HTTP request
- **Fix:**
  ```typescript
  // BEFORE (vulnerable)
  db.query(`SELECT * FROM users WHERE name LIKE '%${req.query.name}%'`)

  // AFTER (secure)
  db.query('SELECT * FROM users WHERE name LIKE ?', [`%${req.query.name}%`])
  ```
- **References:** [OWASP SQL Injection](https://owasp.org/www-community/attacks/SQL_Injection)

### Summary & Recommendations
[Ordered by priority with effort estimates]
```

## Severity Classification Guide

| Severity | Criteria | SLA |
|----------|---------|-----|
| 🔴 Critical | Remotely exploitable, data breach possible | Fix immediately |
| 🟠 High | Exploitable with minimal effort, significant impact | Fix within 24h |
| 🟡 Medium | Exploitable under specific conditions | Fix within 1 week |
| 🟢 Low | Best practice violation, limited impact | Fix in next sprint |
| 💡 Info | Improvement suggestion, no direct risk | Backlog |

## Guardrails

- NEVER report a finding without a concrete fix
- NEVER suggest disabling security features as a fix
- ALWAYS verify the fix doesn't introduce new vulnerabilities
- ALWAYS distinguish between confirmed and potential findings
- NEVER skip dependency scanning because "it looks fine"
- ALWAYS check configuration files, not just source code
- ALWAYS consider the attack surface from an external perspective

## Integration Patterns

### Pre-commit Hook
```bash
# .git/hooks/pre-commit
npx code-guard scan --severity high --fail-on critical --diff-only
```

### CI/CD Pipeline
```yaml
# GitHub Actions
- name: Security Audit
  run: npx code-guard scan --format sarif --output results.sarif
```

### IDE Integration
```json
// VS Code settings.json
{
  "code-guard.severityThreshold": "medium",
  "code-guard.scanOnSave": true
}
```

## Related Skills
- [portable-skills](../portable-skills/) — Cross-agent portability standard
- [code-review-quality](../code-review-quality/) — General code review quality
