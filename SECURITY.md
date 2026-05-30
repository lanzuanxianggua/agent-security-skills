# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a vulnerability in this project, please report it responsibly:

1. **Do not** open a public GitHub issue.
2. Email the maintainer or use [GitHub Security Advisories](https://github.com/lanzuanxianggua/agent-security-skills/security/advisories/new).
3. Include a clear description of the vulnerability, affected files, and any proof of concept.
4. We will acknowledge your report within 48 hours and aim to provide a fix within 7 days.

## Scope

**In scope:**
- The convert.sh script (command injection, path traversal)
- Schema files (injection vectors, validation bypass)
- Secret detection patterns (false negatives that miss real secrets)
- Reference documentation (incorrect security guidance)

**Out of scope:**
- Third-party tools referenced in documentation (semgrep, trufflehog, etc.)
- Vulnerabilities in code written by users of this skill

## Security Considerations

This project contains secret detection patterns and regex examples for educational purposes. All example keys and credentials in reference files are fictitious and should not be treated as real secrets.
