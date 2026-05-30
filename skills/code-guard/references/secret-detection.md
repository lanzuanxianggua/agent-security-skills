# Secret Detection Reference

## Detection Patterns by Language

### JavaScript / TypeScript
```regex
# AWS Access Key
AKIA[0-9A-Z]{16}

# AWS Secret Key (near AWS key context)
(?i)aws[_\-]?secret[_\-]?access[_\-]?key\s*[=:]\s*['"][A-Za-z0-9/+=]{40}['"]

# Generic API Key
(?i)(api[_\-]?key|apikey|api[_\-]?secret)\s*[=:]\s*['"][A-Za-z0-9_\-]{20,}['"]

# Database URLs
(?i)(mysql|postgres|postgresql|mongodb|redis)://[^\s'"]+

# JWT Secret
(?i)jwt[_\-]?(secret|key|token)\s*[=:]\s*['"][^'"]{10,}['"]

# Private Keys
-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----

# Bearer Tokens
(?i)bearer\s+[A-Za-z0-9_\-\.]{20,}

# GitHub Token
gh[ps]_[A-Za-z0-9_]{36,}

# Slack Token
xox[baprs]-[0-9]{10,}-[0-9]{10,}-[0-9a-zA-Z]{24,}

# Stripe Key
(?:rk|sk)_(test|live)_[A-Za-z0-9]{24,}

# SendGrid Key
SG\.[A-Za-z0-9_\-]{22}\.[A-Za-z0-9_\-]{43}

# Twilio Key
SK[A-Za-z0-9]{32}

# Google API Key
AIza[0-9A-Za-z_\-]{35}

# Google OAuth
[0-9]+-[a-z0-9_]{32}\.apps\.googleusercontent\.com
```

### Python
```regex
# Django Secret Key
SECRET_KEY\s*=\s*['"][^'"]{20,}['"]

# Flask Secret
(?i)(secret_key|app\.secret)\s*=\s*['"][^'"]+['"]

# Python dotenv
(password|secret|token|key|api_key)\s*=\s*[^\s#]+

# Environment variable secrets
os\.environ\[['"](.*?(?:KEY|SECRET|TOKEN|PASSWORD|CREDENTIAL).*)['"]\]\s*=\s*['"][^'"]+['"]
```

### Java / Spring
```regex
# Properties file secrets
(?i)(password|secret|token|api[_\-]?key|credentials)\s*=\s*[^\s#]+

# Spring config
spring\.(datasource\.(password|username)|security\.oauth2\.client\.(secret|registration))

# Hardcoded in code
(?i)new\s+(SecretKeySpec|PasswordAuthentication)\s*\([^)]*['"][^'"]+['"]
```

### Go
```regex
# Go secrets
(?i)(os\.Getenv\(['"][^'"]*(?:KEY|SECRET|TOKEN|PASSWORD)[^'"]*['"])\s*[=:])

# Hardcoded credentials
(?i)(const|var)\s+\w*(?:key|secret|token|password)\w*\s*=\s*['"][^'"]+['"]
```

### Docker / Config
```regex
# Environment variables in Dockerfile/compose
(?i)(password|secret|token|key|credential)=\S+

# .env file secrets
(?i)^[A-Z_]*(?:KEY|SECRET|TOKEN|PASSWORD|CREDENTIAL)[A-Z_]*=\S+

# Kubernetes secrets (base64 encoded)
(?i)(password|token|key):\s*[A-Za-z0-9+/=]{20,}
```

## False Positive Reduction

### Common False Positives to Exclude
| Pattern | Why it's a FP | Exclusion |
|---------|--------------|-----------|
| `password: ""` | Empty password placeholder | Skip empty strings |
| `api_key: "YOUR_API_KEY"` | Placeholder text | Skip common placeholders |
| `secret: ${env.SECRET}` | Env variable reference | Skip `${...}` references |
| `token: process.env.TOKEN` | Env variable reference | Skip `process.env.*` |
| `password: "test"` | Test fixture | Flag at reduced severity |
| `secret: "secret"` | Literal "secret" | Skip dictionary words |
| `key: "xxx"` | Masked value | Skip `x+`, `*+`, `#+` patterns |

### Placeholder Patterns (Safe to Ignore)
```
YOUR_API_KEY
<API_KEY>
${API_KEY}
$API_KEY
%API_KEY%
[API_KEY]
{API_KEY}
REPLACE_ME
INSERT_KEY_HERE
xxx...xxx
****
```

## Remediation Guide

### Step 1: Rotate Immediately
If a real secret is found in code:
1. Rotate the credential in the provider console
2. Do NOT just delete from code — the secret is in git history
3. Use `git filter-branch` or BFG Repo Cleaner for history cleanup

### Step 2: Use Secrets Management
```typescript
// BAD — hardcoded
const apiKey = "sk_live_abc123";

// GOOD — environment variable
const apiKey = process.env.API_KEY;

// BETTER — secrets manager
import { SecretsManager } from '@aws-sdk/client-secrets-manager';
const { SecretString } = await client.getSecretValue({ SecretId: 'prod/api-key' });
```

### Step 3: Pre-commit Prevention
```bash
# .git/hooks/pre-commit
if ! detect-secrets scan --baseline .secrets.baseline 2>/dev/null; then
  echo "ERROR: Secrets detected! Use environment variables instead."
  exit 1
fi
```

### Step 4: CI/CD Integration
```yaml
# GitHub Actions
- name: Secret Scan
  uses: trufflesecurity/trufflehog@main
  with:
    extra_args: --only-verified
```

## Entropy Analysis

High-entropy strings (> 4.5 bits/char) are likely secrets:
```python
import math
from collections import Counter

def entropy(s: str) -> float:
    counts = Counter(s)
    total = len(s)
    return -sum((c/total) * math.log2(c/total) for c in counts.values())

# Example: "AKIAIOSFODNN7EXAMPLE" → entropy ≈ 3.8 (moderate)
# Example: "sk_live_EXAMPLE_REPLACE_WITH_REAL_KEY" → entropy ≈ 4.7 (high — likely secret)
```
