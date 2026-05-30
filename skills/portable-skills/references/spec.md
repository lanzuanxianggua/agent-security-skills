# Agent Skills Open Specification v1.0

## Overview

The Agent Skills specification defines a universal format for creating portable, reusable skill packages that work across AI coding agents. A skill is a folder of instructions, scripts, and resources that gives an agent specialized capabilities.

## Format

### Required Structure
```
skill-name/
├── SKILL.md          # Required — skill definition
├── manifest.json     # Required — compatibility & metadata
└── references/       # Optional — supporting docs
    └── *.md
```

### SKILL.md Format

SKILL.md is a Markdown file with YAML frontmatter:

```yaml
---
name: skill-name          # Required — kebab-case, unique identifier
description: "..."        # Required — one-line description
category: security        # Optional — classification
priority: high            # Optional — importance level
tags: [tag1, tag2]        # Optional — for searchability
---
```

Followed by Markdown body with these optional sections:

1. `<default_to_action>` — Behavioral instructions loaded immediately
2. `## When to Use` — Trigger conditions
3. `## Workflow` — Step-by-step process
4. `## Guardrails` — Safety constraints
5. `## Related Skills` — Links to other skills

### manifest.json Format

```json
{
  "name": "skill-name",
  "version": "1.0.0",
  "description": "What this skill does",
  "author": "author-name",
  "license": "MIT",
  "sourceFormat": "universal",
  "compatibility": {
    "claude-code": { "status": "full|partial|experimental", "minVersion": "1.0.0" },
    "cursor": { "status": "full|partial|experimental" },
    "windsurf": { "status": "full|partial|experimental" },
    "copilot": { "status": "full|partial|experimental" }
  }
}
```

## Platform Mapping Rules

### File Location Mapping

| Platform | Primary Location | Format |
|----------|-----------------|--------|
| Claude Code | `~/.claude/skills/<name>/SKILL.md` | Markdown + frontmatter |
| Cursor | `.cursor/rules/<name>.mdc` | MDC format |
| Windsurf | `.windsurf/rules/<name>.md` | Markdown + frontmatter |
| Copilot | `.github/copilot-instructions.md` | Plain Markdown |
| Agent Skills | `.agent/skills/<name>/SKILL.md` | Markdown + frontmatter |

### Frontmatter Mapping

| Universal Field | Claude Code | Cursor MDC | Windsurf | Copilot |
|----------------|-------------|------------|----------|---------|
| `name` | Used as-is | `name` in frontmatter | Used as-is | H1 heading |
| `description` | Used as-is | `description` in frontmatter | Used as-is | First paragraph |
| `triggers` | Skill invocation | `globs` + `description` | Rule trigger | "When to use" section |
| `category` | Preserved | `metadata.category` | Preserved | Ignored |
| `tags` | Preserved | `metadata.tags` | Preserved | Ignored |

### Body Mapping

| Section | All Platforms | Notes |
|---------|:------------:|-------|
| `<default_to_action>` | ✅ | Core behavior — all agents read this |
| `## When to Use` | ✅ | Trigger conditions |
| `## Workflow` | ✅ | Process steps |
| Checklists / Tables | ✅ | All agents render Markdown |
| Code blocks | ✅ | Examples and patterns |
| `<agent:claude-code>` | Claude Code only | Conditional sections |
| `schemas/` | Claude Code only | JSON schemas for output |
| `scripts/` | Bash-capable only | Shell scripts |

## Validation Rules

A valid universal skill MUST:
1. Have a `SKILL.md` with YAML frontmatter containing at least `name` and `description`
2. Have a `manifest.json` with at least `name`, `version`, and `compatibility`
3. Use only standard Markdown in the body (no HTML except `<default_to_action>`)
4. Not reference agent-specific tools without a universal fallback
5. Be self-contained (no required external dependencies)

A valid universal skill SHOULD:
1. Include a `<default_to_action>` block for immediate behavioral guidance
2. Include trigger descriptions for each supported platform
3. Reference supporting documents from `references/` rather than inlining everything
4. Declare platform compatibility with specific status per platform
5. Follow semantic versioning

## Extension Points

Platforms MAY define extensions:
- **Claude Code**: `schemas/`, `scripts/`, `agents` frontmatter field
- **Cursor**: MDC frontmatter fields (`globs`, `alwaysApply`, `description`)
- **Windsurf**: Custom trigger configurations
- **Copilot**: Workspace-specific instructions

Extensions MUST NOT break the universal format. Agents that don't understand an extension MUST ignore it gracefully.

## Versioning

- Skills follow semver: `MAJOR.MINOR.PATCH`
- `MAJOR`: Breaking changes to skill behavior
- `MINOR`: New features, backward compatible
- `PATCH`: Bug fixes, no behavior change

## Security

- Skills MUST NOT execute arbitrary code without user consent
- Skills MUST NOT access files outside the project directory without explicit permission
- Skills MUST NOT transmit code or data to external services
- Skills SHOULD declare required tools and permissions in manifest.json
