# Compliance Framework Reference

## GDPR (General Data Protection Regulation)

### Key Requirements for Code
| Requirement | Code Impact | Detection Pattern |
|-------------|------------|-------------------|
| Data minimization | Only collect necessary PII | Forms/tables with excessive fields |
| Right to erasure | `DELETE` user data on request | Missing `deleteUser()` or incomplete deletion |
| Consent tracking | Record when/how consent given | No consent field in user model |
| Data breach notification | Log and alert on unauthorized access | Missing breach detection logic |
| Privacy by design | Encrypt PII, limit access | Plaintext PII in DB/API responses |
| Data portability | Export user data in standard format | Missing export endpoint |

### GDPR-Audit Checklist
```markdown
- [ ] PII fields encrypted at rest
- [ ] PII fields encrypted in transit (TLS)
- [ ] User deletion endpoint deletes ALL related data
- [ ] Consent timestamps recorded
- [ ] Data processing purposes documented in code comments
- [ ] No PII in logs (redact before logging)
- [ ] Data retention policies implemented (auto-delete old data)
- [ ] Access control on PII endpoints
- [ ] Data export endpoint (JSON/CSV format)
- [ ] Cookie consent banner (frontend)
```

### PII Field Detection
```typescript
// Common PII field names to scan for
const PII_FIELDS = [
  'email', 'phone', 'mobile', 'ssn', 'social_security',
  'date_of_birth', 'dob', 'birth_date', 'birthday',
  'address', 'street', 'city', 'zip', 'postal',
  'first_name', 'last_name', 'full_name',
  'passport', 'driver_license', 'national_id',
  'credit_card', 'card_number', 'cvv', 'expiry',
  'ip_address', 'device_id', 'location', 'coordinates',
  'biometric', 'fingerprint', 'face_id',
  'health', 'medical', 'diagnosis', 'prescription'
];
```

## HIPAA (Health Insurance Portability and Accountability Act)

### PHI (Protected Health Information) Requirements
| Requirement | Implementation |
|-------------|---------------|
| Encryption at rest | AES-256 for all PHI storage |
| Encryption in transit | TLS 1.2+ for all PHI transmission |
| Access control | Role-based access with audit logs |
| Minimum necessary | Limit PHI access to required fields only |
| Audit trail | Log all PHI access with user, time, action |
| Backup & recovery | Encrypted backups with tested restore |
| Integrity controls | Checksums/signatures on PHI records |

### PHI Detection Patterns
```
- Medical record numbers (MRN)
- Health plan beneficiary numbers
- Diagnosis codes (ICD-10 patterns)
- Prescription/medication data
- Lab results and values
- Device identifiers (medical devices)
- Biometric data references
- Any data that can identify a patient
```

## PCI-DSS (Payment Card Industry Data Security Standard)

### Cardholder Data Protection
| Requirement | Detection |
|-------------|-----------|
| PAN encryption | Card numbers stored without encryption |
| Mask display | Full card numbers shown in UI |
| No CVV storage | CVV/CVC stored in database |
| Network segmentation | Card data network not isolated |
| Access logging | Missing audit trail for card data access |
| Vulnerability scanning | No regular security scans |

### PAN Detection (Card Number Validation)
```typescript
// Luhn algorithm for card number validation
function isLikelyCardNumber(value: string): boolean {
  const digits = value.replace(/\D/g, '');
  if (digits.length < 13 || digits.length > 19) return false;

  let sum = 0;
  let isEven = false;
  for (let i = digits.length - 1; i >= 0; i--) {
    let digit = parseInt(digits[i]);
    if (isEven) {
      digit *= 2;
      if (digit > 9) digit -= 9;
    }
    sum += digit;
    isEven = !isEven;
  }
  return sum % 10 === 0;
}
```

## SOC2 / SOC 2 (Service Organization Control 2)

> **Note:** The audit output schema (`schemas/audit-output.json`) uses the
> canonical enum value **`SOC2`** (no space). Always reference the framework
> as `SOC2` in structured output; "SOC 2" is the human-readable form.

### Trust Service Criteria
| Category | Code-Level Requirements |
|----------|----------------------|
| Security | Access control, encryption, monitoring |
| Availability | Redundancy, failover, health checks |
| Processing Integrity | Input validation, error handling, audit logs |
| Confidentiality | Data classification, encryption, access policies |
| Privacy | PII handling, consent, retention, deletion |

### SOC2 Audit Patterns
```markdown
- [ ] All data access logged with user context
- [ ] Failed access attempts logged and alerted
- [ ] Encryption keys rotated on schedule
- [ ] Infrastructure changes require approval
- [ ] Vulnerability scanning runs on schedule
- [ ] Incident response plan documented and tested
- [ ] Third-party access reviewed quarterly
- [ ] Data classification labels on all data stores
```

## Compliance Output Format

The following example matches the `complianceResult` objects defined in
`schemas/audit-output.json`. Each entry lives in the top-level `compliance`
array and contains: `framework`, `requirement`, `status`, `severity`,
`description`, and `evidence`.

```json
{
  "skillName": "code-guard",
  "version": "1.0.0",
  "timestamp": "2025-06-15T10:30:00Z",
  "status": "findings",
  "findings": [],
  "compliance": [
    {
      "framework": "GDPR",
      "requirement": "Article 17 - Right to Erasure",
      "status": "fail",
      "severity": "high",
      "description": "User deletion endpoint does not remove related order history",
      "evidence": "DELETE query only targets users table; order_history table is not cascaded"
    },
    {
      "framework": "SOC2",
      "requirement": "CC6.1 - Logical and Physical Access Controls",
      "status": "pass",
      "severity": "low",
      "description": "All data access is logged with user context",
      "evidence": "Access log middleware present on all PII endpoints"
    },
    {
      "framework": "HIPAA",
      "requirement": "164.312(a)(1) - Access Control",
      "status": "warning",
      "severity": "medium",
      "description": "PHI access controls exist but lack field-level restrictions",
      "evidence": "RBAC applies at endpoint level only; no column-level ACLs"
    },
    {
      "framework": "PCI-DSS",
      "requirement": "Req 3.4 - Render PAN Unreadable",
      "status": "fail",
      "severity": "critical",
      "description": "Card numbers stored in plaintext in database",
      "evidence": "payment_cards table stores raw PAN without encryption"
    }
  ],
  "summary": {
    "totalFindings": 0,
    "critical": 0,
    "high": 0,
    "medium": 0,
    "low": 0,
    "info": 0,
    "secretsFound": 0,
    "dependencyVulns": 0,
    "riskScore": 45,
    "riskGrade": "C",
    "verdict": "merge-with-caution"
  }
}
```
