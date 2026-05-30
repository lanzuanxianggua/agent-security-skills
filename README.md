# Agent Security Skills

> Portable AI coding agent skills for security auditing and cross-agent compatibility. Write once, run on Claude Code, Cursor, Windsurf, GitHub Copilot, and any Agent Skills compatible tool.

## Skills

### code-guard — AI Code Security Audit

Scans code for OWASP Top 10 vulnerabilities, leaked secrets, insecure dependencies, and compliance violations. Every finding includes a concrete fix, not just a warning.

**Features:**
- OWASP Top 10 (2021) vulnerability detection patterns with code fixes
- Secret/credential leak detection (AWS keys, GitHub tokens, private keys, etc.)
- Dependency vulnerability audit (npm, pip, maven, cargo, go)
- Compliance framework checks (GDPR, HIPAA, PCI-DSS, SOC 2)
- Structured findings with severity classification (Critical → Info)
- Pre-commit hook and CI/CD integration patterns

### portable-skills — Cross-Agent Skill Standard

Defines a universal skill format and provides conversion tools for making skills portable across all major AI coding agents.

**Features:**
- Universal SKILL.md format specification (v1.0)
- Detailed compatibility matrix (Claude Code, Cursor, Windsurf, Copilot, Aider)
- Conversion CLI for batch skill transformation
- Platform-specific file location mapping
- Graceful degradation patterns
- JSON schema for skill validation

## Quick Start

### Install via Skills CLI

```bash
# Install code-guard
npx skills add your-username/agent-security-skills@code-guard -g -y

# Install portable-skills
npx skills add your-username/agent-security-skills@portable-skills -g -y
```

### Install Manually (Claude Code)

```bash
# Clone the repo
git clone https://github.com/your-username/agent-security-skills.git

# Symlink skills to Claude Code
ln -s $(pwd)/agent-security-skills/skills/code-guard ~/.claude/skills/code-guard
ln -s $(pwd)/agent-security-skills/skills/portable-skills ~/.claude/skills/portable-skills
```

### Install for Cursor

```bash
# Convert skills to Cursor format
./scripts/convert.sh --input ./skills/code-guard/ --target cursor

# Or copy the converted file
cp -r .cursor/rules/ /path/to/your/project/.cursor/rules/
```

### Install for Windsurf

```bash
./scripts/convert.sh --input ./skills/code-guard/ --target windsurf
cp -r .windsurf/rules/ /path/to/your/project/.windsurf/rules/
```

### Install for GitHub Copilot

```bash
./scripts/convert.sh --input ./skills/code-guard/ --target copilot
cp .github/copilot-instructions.md /path/to/your/project/.github/copilot-instructions.md
```

### Convert All Skills to All Platforms

```bash
./scripts/convert.sh --input ./skills/code-guard/ --target all --output ./release/
```

## Usage

### code-guard

In Claude Code, type:
```
/code-guard scan the authentication module for security issues
```

Or simply describe what you need:
```
Audit the API endpoints for OWASP vulnerabilities and check for leaked secrets
```

The skill will:
1. Scan code for injection, auth, crypto, and access control issues
2. Detect hardcoded secrets and credentials
3. Audit dependencies for known CVEs
4. Check compliance against GDPR/HIPAA/PCI-DSS as applicable
5. Produce a structured report with severity ratings and concrete fixes

### portable-skills

Use when creating or converting skills:
```
/portable-skills convert my-skill to cursor format
```

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
```

## Validation

```bash
# Validate a skill's portability
./scripts/convert.sh --validate ./skills/code-guard/

# Check compatibility for a specific platform
./scripts/convert.sh --check ./skills/code-guard/ --platform cursor
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-skill`)
3. Follow the universal skill format (see `portable-skills` skill)
4. Include `manifest.json` with compatibility declarations
5. Test on at least 2 platforms before submitting
6. Submit a pull request

## License

MIT License — see [LICENSE](LICENSE) for details.
