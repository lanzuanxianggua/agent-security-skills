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

### One-Command Install (Recommended)

```bash
# Install code-guard — instant security audit in your AI agent
npx skills add lanzuanxianggua/agent-security-skills --skill code-guard -g -y

# Install portable-skills — write once, run everywhere
npx skills add lanzuanxianggua/agent-security-skills --skill portable-skills -g -y

# Or install everything at once
npx skills add lanzuanxianggua/agent-security-skills --all -g -y
```

Then in Claude Code:
```
/code-guard audit the authentication module for security issues
```

That's it. No clone, no config, no CI pipeline. Works in Claude Code immediately.

### Cursor

```bash
npx skills add lanzuanxianggua/agent-security-skills --skill code-guard -g -y
```

Or convert manually:
```bash
git clone https://github.com/lanzuanxianggua/agent-security-skills.git
cd agent-security-skills
./scripts/convert.sh --input ./skills/code-guard/ --target cursor
cp -r dist/.cursor/rules/ /your/project/.cursor/rules/
```

### Windsurf

```bash
npx skills add lanzuanxianggua/agent-security-skills --skill code-guard -g -y
```

Or convert manually:
```bash
./scripts/convert.sh --input ./skills/code-guard/ --target windsurf
cp -r dist/.windsurf/rules/ /your/project/.windsurf/rules/
```

### GitHub Copilot

```bash
git clone https://github.com/lanzuanxianggua/agent-security-skills.git
cd agent-security-skills
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
│   │   │   ├── compliance-frameworks.md # GDPR, HIPAA, PCI-DSS, SOC 2
│   │   │   └── additional-vulns.md      # Advanced vulnerability patterns
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
├── tests/
│   ├── convert.bats                  # Test suite
│   └── run.sh                        # Test runner
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

---

# 中文文档

> **用 AI 对你的代码进行安全审计 — 并让它在所有 AI 编码助手之间通用。**
> OWASP Top 10、密钥检测、依赖审计、合规检查，一个可移植的技能包全部搞定。

---

## 它能做什么

### code-guard — AI 编码助手中的即时安全审计

不需要单独的 CLI 工具，不需要配置 CI 流水线。直接让你的 AI 编码助手审计你的代码。

**修复前**（有漏洞）:
```typescript
// SQL 注入 — 攻击者可以拖走整个数据库
app.get('/users', (req, res) => {
  db.query(`SELECT * FROM users WHERE name = '${req.query.name}'`);
});
```

**修复后**（code-guard 修复）:
```typescript
// 参数化查询 — 防注入
app.get('/users', (req, res) => {
  db.query('SELECT * FROM users WHERE name = ?', [req.query.name]);
});
```

**审计输出示例：**
```
🔴 严重 CG-001: 用户搜索中的 SQL 注入
   位置: src/api/users.ts:3
   可利用性: 简单 — 单个 HTTP 请求即可触发
   修复: 使用参数化查询（见上方）

🔴 严重 SEC-002: 硬编码的 AWS 访问密钥
   位置: config/production.ts:12
   置信度: 高
   修复: 迁移至环境变量，立即轮换密钥

🟡 中等 CG-003: 登录接口缺少速率限制
   位置: src/routes/auth.ts:45
   修复: 添加速率限制中间件
```

### portable-skills — 一次编写，到处运行

用通用格式编写一次技能包，转换为任何 AI 编码助手可用的格式：

```
                    ┌─────────────┐
                    │  SKILL.md   │  通用格式
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

## 功能特性

- **OWASP Top 10** 漏洞检测，提供 TypeScript、Python、Go、Java 的代码修复建议
- **凭据与密钥检测** — AWS 密钥、GitHub 令牌、Stripe 密钥、SSH 私钥、JWT 密钥等 15+ 种类型
- **依赖审计** — npm、pip、maven、cargo、go，支持 CVE 追踪
- **合规检查** — GDPR、HIPAA、PCI-DSS、SOC 2
- **跨平台移植** — 支持 Claude Code、Cursor、Windsurf、GitHub Copilot
- **转换 CLI** — 一条命令将技能包转换为任意平台格式
- **结构化输出** — JSON Schema，方便集成到 CI/CD 流水线

---

## 为什么不用 semgrep / SonarQube / Snyk？

| | code-guard | semgrep | SonarQube | Snyk |
|---|:---:|:---:|:---:|:---:|
| 在 AI 编码助手中运行 | 是 | 否 | 否 | 否 |
| 跨 AI 工具通用 | 是 | 不适用 | 不适用 | 不适用 |
| 提供修复建议 | 是 | 部分 | 部分 | 部分 |
| 零配置 / 一条命令安装 | 是 | 否 | 否 | 否 |
| OWASP + 密钥 + 合规 | 是 | 仅规则 | 仅规则 | 仅依赖 |
| 离线使用 | 是 | 是 | 否 | 否 |
| 免费开源 | 是 | 部分 | 部分 | 部分 |

code-guard 不替代 SAST 工具 — 它将安全意识**直接融入你的 AI 编码工作流**，在你每天编写和审查代码的地方发挥作用。

---

## 快速开始

### 一键安装（推荐）

```bash
# 安装 code-guard — AI 助手中的即时安全审计
npx skills add lanzuanxianggua/agent-security-skills --skill code-guard -g -y

# 安装 portable-skills — 一次编写，到处运行
npx skills add lanzuanxianggua/agent-security-skills --skill portable-skills -g -y

# 或一次性安装全部
npx skills add lanzuanxianggua/agent-security-skills --all -g -y
```

然后在 Claude Code 中：
```
/code-guard 审计认证模块的安全问题
```

就这么简单。无需克隆、无需配置、无需 CI 流水线。在 Claude Code 中立即可用。

### Cursor

```bash
npx skills add lanzuanxianggua/agent-security-skills --skill code-guard -g -y
```

或手动转换：
```bash
git clone https://github.com/lanzuanxianggua/agent-security-skills.git
cd agent-security-skills
./scripts/convert.sh --input ./skills/code-guard/ --target cursor
cp -r dist/.cursor/rules/ /你的项目/.cursor/rules/
```

### Windsurf

```bash
npx skills add lanzuanxianggua/agent-security-skills --skill code-guard -g -y
```

或手动转换：
```bash
./scripts/convert.sh --input ./skills/code-guard/ --target windsurf
cp -r dist/.windsurf/rules/ /你的项目/.windsurf/rules/
```

### GitHub Copilot

```bash
git clone https://github.com/lanzuanxianggua/agent-security-skills.git
cd agent-security-skills
./scripts/convert.sh --input ./skills/code-guard/ --target copilot
cp dist/.github/copilot-instructions.md /你的项目/.github/copilot-instructions.md
```

### 批量转换为所有平台

```bash
./scripts/convert.sh --input ./skills/code-guard/ --target all --output ./release/
```

---

## 使用方法

### code-guard 安全审计

让你的 AI 助手审计代码：
```
/code-guard 扫描认证模块的安全问题
```

或描述你的需求：
```
审计 API 接口的 OWASP 漏洞并检查泄露的密钥
```

技能包将会：
1. 扫描代码中的注入、认证、加密和访问控制问题
2. 检测硬编码的密钥和凭据
3. 审计依赖项的已知 CVE 漏洞
4. 检查 GDPR/HIPAA/PCI-DSS 合规性
5. 生成结构化报告，包含严重等级和具体修复建议

### portable-skills 跨平台标准

创建或转换技能包时使用：
```
/portable-skills 将 my-skill 转换为 cursor 格式
```

---

## 项目结构

```
agent-security-skills/
├── README.md
├── LICENSE
├── scripts/
│   └── convert.sh                    # 跨平台转换 CLI
├── skills/
│   ├── code-guard/
│   │   ├── SKILL.md                  # 技能包定义
│   │   ├── manifest.json             # 兼容性清单
│   │   ├── references/
│   │   │   ├── owasp-top10.md        # OWASP Top 10 检测与修复模式
│   │   │   ├── dependency-security.md # 依赖审计指南
│   │   │   ├── secret-detection.md   # 密钥检测正则与修复指南
│   │   │   ├── compliance-frameworks.md # GDPR、HIPAA、PCI-DSS、SOC 2
│   │   │   └── additional-vulns.md      # 高级漏洞模式
│   │   └── schemas/
│   │       └── audit-output.json     # 结构化输出 Schema
│   └── portable-skills/
│       ├── SKILL.md
│       ├── manifest.json
│       ├── references/
│       │   ├── spec.md               # 开放规范 v1.0
│       │   ├── compatibility-matrix.md # 平台功能支持矩阵
│       │   └── migration-guide.md    # 转换指南
│       └── schemas/
│           └── portable-skill-schema.json # 技能包验证 Schema
├── tests/
│   ├── convert.bats
│   └── run.sh
└── examples/
    └── sample-audit-report.md        # code-guard 输出示例
```

---

## 验证

```bash
# 验证技能包的可移植性
./scripts/convert.sh --validate ./skills/code-guard/

# 检查特定平台的兼容性
./scripts/convert.sh --check ./skills/code-guard/ --platform cursor
```

---

## 贡献

详见 [CONTRIBUTING.md](CONTRIBUTING.md)。

简要步骤：
1. Fork 本仓库
2. 创建功能分支（`git checkout -b feature/my-skill`）
3. 遵循通用技能包格式（参见 `portable-skills` 技能包）
4. 包含 `manifest.json` 兼容性声明
5. 提交前至少在 2 个平台上测试
6. 提交 Pull Request

## 许可证

MIT 许可证 — 详见 [LICENSE](LICENSE)。
