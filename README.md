# Agent Security Skills

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![GitHub Stars](https://img.shields.io/github/stars/lanzuanxianggua/agent-security-skills?style=social)](https://github.com/lanzuanxianggua/agent-security-skills)
[![Platform: Claude Code](https://img.shields.io/badge/Claude%20Code-Full-green.svg)]()
[![Platform: Cursor](https://img.shields.io/badge/Cursor-Full-green.svg)]()
[![Platform: Windsurf](https://img.shields.io/badge/Windsurf-Full-green.svg)]()
[![Platform: Copilot](https://img.shields.io/badge/Copilot-Partial-yellow.svg)]()

> **Security-audit your code with AI — and make it work on every AI coding agent.**
> OWASP Top 10, secret detection, dependency audit, and compliance checks in one portable skill.

---

## What It Does

### code-guard — Instant Security Audit in Your AI Agent

No separate CLI tool, no CI pipeline to configure. Just ask your AI coding agent to audit your code.

**Before** (vulnerable):
```typescript
// SQL injection — attacker can dump your entire database
app.get('/users', (req, res) => {
  db.query(`SELECT * FROM users WHERE name = '${req.query.name}'`);
});
```

**After** (code-guard fix):
```typescript
// Parameterized query — injection-proof
app.get('/users', (req, res) => {
  db.query('SELECT * FROM users WHERE name = ?', [req.query.name]);
});
```

**Sample audit output:**
```
🔴 CRITICAL CG-001: SQL Injection in User Search
   Location: src/api/users.ts:3
   Exploitability: Trivial — single HTTP request
   Fix: Use parameterized queries (see above)

🔴 CRITICAL SEC-002: Hardcoded AWS Access Key
   Location: config/production.ts:12
   Confidence: High
   Fix: Move to environment variable, rotate immediately

🟡 MEDIUM CG-003: Missing Rate Limiting on Login
   Location: src/routes/auth.ts:45
   Fix: Add rate limiting middleware
```

### portable-skills — Write Once, Run Everywhere

Write a skill once in the universal format, convert it to work on any AI coding agent:

```
                    ┌─────────────┐
                    │  SKILL.md   │  Universal format
                    │ manifest.json│
                    └──────┬──────┘
                           │
            ┌──────────────┼──────────────┐
            ▼              ▼              ▼
    ┌───────────┐  ┌───────────┐  ┌───────────┐
    │  Cursor   │  │ Windsurf  │  │  Copilot  │
    │  .mdc     │  │  .md      │  │  .md      │
    └───────────┘  └───────────┘  └───────────┘
```

---

## Features

- **OWASP Top 10** vulnerability detection with code fixes in TypeScript, Python, Go, Java
- **Secret detection** — AWS keys, GitHub tokens, Stripe keys, private SSH keys, JWT secrets, and 15+ more
- **Dependency audit** — npm, pip, maven, cargo, go with CVE tracking
- **Compliance checks** — GDPR, HIPAA, PCI-DSS, SOC 2
- **Cross-agent portability** — works on Claude Code, Cursor, Windsurf, GitHub Copilot
- **Conversion CLI** — one command to convert skills for any platform
- **Structured output** — JSON schema for integration with CI/CD pipelines

---

## Why Not Just Use semgrep / SonarQube / Snyk?

| | code-guard | semgrep | SonarQube | Snyk |
|---|:---:|:---:|:---:|:---:|
| Works inside your AI agent | Yes | No | No | No |
| Portable across AI tools | Yes | N/A | N/A | N/A |
| Includes fix suggestions | Yes | Partial | Partial | Partial |
| Zero config / copy-paste install | Yes | No | No | No |
| OWASP Top 10 + secrets + compliance | Yes | Rules only | Rules only | Deps only |
| Works offline | Yes | Yes | No | No |
| Free & open source | Yes | Partial | Partial | Partial |

code-guard doesn't replace SAST tools — it brings security awareness directly into your AI coding workflow, where you write and review code every day.

---

## Quick Start

### Claude Code

```bash
# Clone and symlink
git clone https://github.com/lanzuanxianggua/agent-security-skills.git
ln -s $(pwd)/agent-security-skills/skills/code-guard ~/.claude/skills/code-guard
ln -s $(pwd)/agent-security-skills/skills/portable-skills ~/.claude/skills/portable-skills
```

Then in Claude Code:
```
/code-guard audit the authentication module for security issues
```

### Cursor

```bash
git clone https://github.com/lanzuanxianggua/agent-security-skills.git
cd agent-security-skills
./scripts/convert.sh --input ./skills/code-guard/ --target cursor
cp -r dist/.cursor/rules/ /your/project/.cursor/rules/
```

### Windsurf

```bash
./scripts/convert.sh --input ./skills/code-guard/ --target windsurf
cp -r dist/.windsurf/rules/ /your/project/.windsurf/rules/
```

### GitHub Copilot

```bash
./scripts/convert.sh --input ./skills/code-guard/ --target copilot
cp dist/.github/copilot-instructions.md /your/project/.github/copilot-instructions.md
```

### Convert All Skills to All Platforms

```bash
./scripts/convert.sh --input ./skills/code-guard/ --target all --output ./release/
```

---

## Usage

### code-guard Security Audit

Ask your AI agent to audit code:
```
/code-guard scan the authentication module for security issues
```

Or describe what you need:
```
Audit the API endpoints for OWASP vulnerabilities and check for leaked secrets
```

The skill will:
1. Scan code for injection, auth, crypto, and access control issues
2. Detect hardcoded secrets and credentials
3. Audit dependencies for known CVEs
4. Check compliance against GDPR/HIPAA/PCI-DSS as applicable
5. Produce a structured report with severity ratings and concrete fixes

### portable-skills Cross-Agent Standard

Use when creating or converting skills:
```
/portable-skills convert my-skill to cursor format
```

---

## Project Structure

```
agent-security-skills/
├── README.md
├── LICENSE
├── scripts/
│   └── convert.sh                    # Cross-platform conversion CLI
├── skills/
│   ├── code-guard/
│   │   ├── SKILL.md                  # Skill definition
│   │   ├── manifest.json             # Compatibility manifest
│   │   ├── references/
│   │   │   ├── owasp-top10.md        # OWASP Top 10 detection & fix patterns
│   │   │   ├── dependency-security.md # Dependency audit guide
│   │   │   ├── secret-detection.md   # Secret detection regex & remediation
│   │   │   └── compliance-frameworks.md # GDPR, HIPAA, PCI-DSS, SOC 2
│   │   └── schemas/
│   │       └── audit-output.json     # Structured output schema
│   └── portable-skills/
│       ├── SKILL.md
│       ├── manifest.json
│       ├── references/
│       │   ├── spec.md               # Open specification v1.0
│       │   ├── compatibility-matrix.md # Platform feature support
│       │   └── migration-guide.md    # Conversion instructions
│       └── schemas/
│           └── portable-skill-schema.json # Skill validation schema
└── examples/
    └── sample-audit-report.md        # Example code-guard output
```

---

## Validation

```bash
# Validate a skill's portability
./scripts/convert.sh --validate ./skills/code-guard/

# Check compatibility for a specific platform
./scripts/convert.sh --check ./skills/code-guard/ --platform cursor
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

Quick summary:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-skill`)
3. Follow the universal skill format (see `portable-skills` skill)
4. Include `manifest.json` with compatibility declarations
5. Test on at least 2 platforms before submitting
6. Submit a pull request

## License

MIT License — see [LICENSE](LICENSE) for details.
