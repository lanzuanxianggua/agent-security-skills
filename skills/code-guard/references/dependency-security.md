# Dependency Security Audit Guide

## Quick Scan Commands

### Node.js / npm
```bash
# Full audit
npm audit

# JSON output for parsing
npm audit --json

# Fix automatically where possible
npm audit --fix

# Check for outdated packages
npx npm-check-updates

# License audit
npx license-checker --summary
```

### Python / pip
```bash
# Using pip-audit
pip-audit -r requirements.txt

# Using safety
safety check -r requirements.txt --json

# Using pip-audit on installed packages
pip-audit

# Check for known vulnerabilities
pip check
```

### Java / Maven
```bash
# OWASP Dependency Check
mvn org.owasp:dependency-check-maven:check

# Using Snyk
snyk test --file=pom.xml

# Check for outdated
mvn versions:display-dependency-updates
```

### Go
```bash
# Govulncheck
govulncheck ./...

# Nancy (Sonatype)
nancy sleuth -r go.sum
```

### Rust
```bash
cargo audit
```

## High-Risk Dependency Patterns

### Red Flags in package.json / requirements.txt
| Pattern | Risk | Action |
|---------|------|--------|
| Version range `*` or `latest` | Unpredictable builds | Pin exact version |
| Git URLs without commit hash | Supply chain risk | Pin to commit SHA |
| Packages with < 100 weekly downloads | Unvetted code | Audit source before use |
| Packages not updated in 2+ years | Abandoned, unpatched | Find maintained alternative |
| `optionalDependencies` with native code | Build variability | Lock or remove |
| `postinstall` scripts in dependencies | Arbitrary code execution | Audit install scripts |

### Transitive Dependency Risks
```bash
# Check transitive dependency tree
npm ls --all

# Find which package introduced a vulnerable dep
npm ls <vulnerable-package>

# Check for phantom dependencies
npx check-dependency-version-consistency
```

## Dependency Pinning Strategy

### package.json
```json
{
  "dependencies": {
    "express": "4.18.2",       // Exact version (no ^ or ~)
    "lodash": "4.17.21"
  },
  "overrides": {
    "minimatch": "5.1.2"       // Force specific transitive version
  }
}
```

### Docker Multi-Stage Build
```dockerfile
# Build stage — all deps for building
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage — only production deps and built output
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/package*.json ./
RUN npm ci --omit=dev
COPY --from=builder /app/dist ./dist
CMD ["node", "dist/index.js"]
```

## Automated Dependency Monitoring

### GitHub Dependabot
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    reviewers:
      - "security-team"
```

### Renovate Bot
```json
{
  "extends": ["config:base"],
  "schedule": ["before 5am on Monday"],
  "packageRules": [
    {
      "matchUpdateTypes": ["major"],
      "addLabels": ["major-update"],
      "reviewers": ["security-team"]
    }
  ]
}
```

## Severity Assessment

| CVSS Score | Severity | SLA |
|-----------|----------|-----|
| 9.0–10.0 | Critical | 24h |
| 7.0–8.9 | High | 1 week |
| 4.0–6.9 | Medium | 1 sprint |
| 0.1–3.9 | Low | Backlog |
