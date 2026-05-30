---
name: portable-skills
description: "Cross-agent portable skill standard and toolkit. Write skills once, run on Claude Code, Cursor, Windsurf, GitHub Copilot, and any Agent Skills compatible tool. Includes format specification, conversion tools, and compatibility matrix."
category: tooling
priority: high
tokenEstimate: 1000
tags: [portable, cross-agent, skills, compatibility, cursor, windsurf, copilot, standard]
triggers:
  claude-code:
    - "convert skill for"
    - "/portable-skills"
  cursor:
    - "convert skill to cursor format"
  windsurf:
    - "convert skill to windsurf format"
  copilot:
    - "make skill portable"
compatibility:
  claude-code: full
  cursor: full
  windsurf: full
  copilot: partial
  aider: experimental
---

# Portable Skills — Cross-Agent Skill Standard

<default_to_action>
When creating or converting skills for cross-agent compatibility:
1. VALIDATE the skill against the universal schema before packaging
2. TEST on at least 2 target agents to confirm compatibility
3. CONVERT using the appropriate adapter for each target platform
4. DOCUMENT platform-specific behaviors and limitations
5. PACKAGE with a manifest that declares compatibility

**Quick Compatibility Check:**
- Does the skill use only universal frontmatter fields?
- Are all tool references abstracted or conditionally mapped?
- Is the skill self-contained (no external deps beyond standard tools)?
- Does it include trigger descriptions for each platform?
- Is there a fallback for unsupported features?

**Critical Success Factors:**
- Write once, deploy everywhere — no manual edits per platform
- Graceful degradation — features that don't map should degrade, not break
- Backward compatibility — skills written today must work on older agent versions
- Clear manifest — declare what works and what doesn't on each platform
</default_to_action>

## When to Use

- Creating new skills that should work across multiple AI coding agents
- Converting existing Claude Code skills for use in Cursor, Windsurf, or Copilot
- Building a skill marketplace or registry that serves multiple platforms
- Establishing team-wide skill standards that work regardless of tool choice
- Publishing skills to the open Agent Skills ecosystem

## The Universal Skill Format

### Directory Structure
```
my-skill/
├── SKILL.md              # Primary skill definition (universal)
├── manifest.json         # Compatibility manifest
├── references/           # Supporting documentation
│   └── *.md
├── schemas/              # Output schemas (optional)
│   └── output.json
└── scripts/              # Tool scripts (optional)
    └── *.sh / *.json
```

### SKILL.md Universal Frontmatter
```yaml
---
# === Universal Fields (all agents) ===
name: my-skill                    # Required — kebab-case identifier
description: "One-line summary"   # Required — what this skill does
category: security                # Optional — categorization
priority: high                    # Optional — low, medium, high, critical
tags: [security, audit]           # Optional — discoverability tags

# === Platform-Specific Triggers ===
triggers:
  claude-code:
    - "scan for security issues"
    - "/code-guard"
  cursor:
    - ".cursorrules security scan"
  windsurf:
    - "Windsurf rules security audit"
  copilot:
    - "copilot-instructions security review"

# === Compatibility Declaration ===
compatibility:
  claude-code: full               # full | partial | experimental
  cursor: full
  windsurf: full
  copilot: partial
  aider: experimental

# === Tool Mapping ===
tools:
  universal:                      # Tools available on all platforms
    - Read
    - Write
    - Edit
    - Grep
    - Glob
    - Bash
  platform-specific:
    claude-code:
      - Agent
      - TaskCreate
      - Skill
    cursor:
      - composer
      - terminal
    windsurf:
      - cascade
      - terminal
    copilot:
      - workspace
---
```

## Platform Compatibility Matrix

| Feature | Claude Code | Cursor | Windsurf | Copilot | Aider |
|---------|:-----------:|:------:|:--------:|:-------:|:-----:|
| SKILL.md frontmatter | ✅ Full | ✅ Full | ✅ Full | ⚠️ Partial | ⚠️ Partial |
| `name` field | ✅ | ✅ | ✅ | ✅ | ✅ |
| `description` field | ✅ | ✅ | ✅ | ✅ | ✅ |
| `triggers` block | ✅ | ⚠️ Remapped | ⚠️ Remapped | ❌ Ignored | ❌ Ignored |
| `compatibility` block | ✅ | ✅ | ✅ | ⚠️ Read-only | ⚠️ Read-only |
| `tools` mapping | ✅ | ⚠️ Partial | ⚠️ Partial | ❌ Not supported | ❌ Not supported |
| references/ directory | ✅ | ✅ | ✅ | ❌ | ❌ |
| schemas/ directory | ✅ | ❌ | ❌ | ❌ | ❌ |
| scripts/ directory | ✅ | ⚠️ Bash only | ⚠️ Bash only | ❌ | ⚠️ Bash only |
| Markdown body | ✅ Full | ✅ Full | ✅ Full | ✅ Partial | ✅ Full |
| Default-to-action | ✅ | ✅ | ✅ | ⚠️ As context | ✅ |
| Checklist blocks | ✅ | ✅ | ✅ | ✅ | ✅ |
| Code examples | ✅ | ✅ | ✅ | ✅ | ✅ |
| Conditional sections | ✅ | ❌ | ❌ | ❌ | ❌ |

### Platform File Locations

| Platform | Skill Location | Format |
|----------|---------------|--------|
| Claude Code | `~/.claude/skills/<name>/SKILL.md` or `.claude/skills/<name>/SKILL.md` | Markdown with frontmatter |
| Cursor | `.cursor/rules/<name>.mdc` | Markdown with frontmatter |
| Windsurf | `.windsurfrules` or `.windsurf/rules/<name>.md` | Markdown with frontmatter |
| Copilot | `.github/copilot-instructions.md` | Markdown (flat, no frontmatter) |
| Aider | `.aider.conf.yml` + conventions in `.aider/` | YAML + Markdown |
| Agent Skills (open) | `.agent/skills/<name>/SKILL.md` | Markdown with frontmatter |

## Conversion Rules

### Claude Code → Cursor
```
Transforms:
- SKILL.md → .cursor/rules/<name>.mdc
- frontmatter name → rule name header
- frontmatter triggers → .mdc globs/description fields
- references/ → inline at bottom of file
- schemas/ → drop (not supported)
- scripts/ → keep bash scripts, reference from body

CLI: npx portable-skills convert --from claude-code --to cursor --input ./my-skill/
```

### Claude Code → Windsurf
```
Transforms:
- SKILL.md → .windsurf/rules/<name>.md
- frontmatter preserved as YAML comment block
- references/ → inline at bottom
- schemas/ → drop
- scripts/ → keep bash scripts

CLI: npx portable-skills convert --from claude-code --to windsurf --input ./my-skill/
```

### Claude Code → Copilot
```
Transforms:
- SKILL.md → .github/copilot-instructions.md (appended)
- frontmatter → stripped, description becomes heading
- triggers → added as "When to use" section
- references/ → inline as sections
- schemas/, scripts/ → drop
- Tool-specific instructions → commented out with note

CLI: npx portable-skills convert --from claude-code --to copilot --input ./my-skill/
```

### Universal → Any Platform
```
The universal format is a superset. Conversion to any platform:
1. Parse SKILL.md frontmatter
2. Map trigger syntax to target platform
3. Inline references into body if target doesn't support references/
4. Strip platform-incompatible sections (mark as comments)
5. Generate target file at correct location
6. Write manifest.json with conversion metadata

CLI: npx portable-skills convert --input ./my-skill/ --target all
```

## Manifest Schema

Every portable skill MUST include a `manifest.json`:

```json
{
  "name": "my-skill",
  "version": "1.0.0",
  "description": "What this skill does",
  "author": "your-name",
  "license": "MIT",
  "sourceFormat": "universal",
  "compatibility": {
    "claude-code": { "status": "full", "minVersion": "1.0.0" },
    "cursor": { "status": "full", "minVersion": "0.45" },
    "windsurf": { "status": "full", "minVersion": "1.0" },
    "copilot": { "status": "partial", "notes": "No schema support" },
    "aider": { "status": "experimental", "notes": "Basic support only" }
  },
  "files": {
    "skill": "SKILL.md",
    "manifest": "manifest.json",
    "references": ["references/*.md"],
    "schemas": ["schemas/*.json"],
    "scripts": ["scripts/*"]
  },
  "conversions": {
    "cursor": { "output": ".cursor/rules/<name>.mdc", "transform": "mdc" },
    "windsurf": { "output": ".windsurf/rules/<name>.md", "transform": "windsurf" },
    "copilot": { "output": ".github/copilot-instructions.md", "transform": "append" }
  }
}
```

## Writing Portable Skills — Best Practices

### DO
- Use only universal frontmatter fields (`name`, `description`, `category`, `tags`)
- Keep the SKILL.md body as pure Markdown
- Use `<default_to_action>` blocks for behavioral instructions
- Include platform-specific sections as clearly marked blocks
- Test on at least Claude Code + one other agent before publishing
- Provide a `manifest.json` declaring compatibility
- Use Bash for scripts (universal across all agents)

### DON'T
- Use agent-specific tool calls in the main skill body without alternatives
- Rely on frontmatter features only one agent supports
- Hard-code file paths specific to one platform
- Use HTML or non-standard Markdown extensions
- Assume any specific directory structure beyond SKILL.md at root

### Graceful Degradation Pattern
```markdown
## Advanced Features

<agent:claude-code>
This skill supports parallel agent dispatch for faster scanning:
\`\`\`typescript
await Agent({ prompt: "scan code for injection", subagent_type: "Explore" })
\`\`\`
</agent:claude-code>

<agent:universal>
For advanced parallel scanning, use your agent's task delegation feature
to run multiple scan passes simultaneously.
</agent:universal>
```

## Conversion CLI (convert.sh)

The conversion tool is at `scripts/convert.sh` in the project root.

```bash
# Convert a single skill
./scripts/convert.sh --input ./skills/code-guard/ --target cursor

# Convert all skills in a directory
./scripts/convert.sh --input ./skills/ --target all --output ./converted/

# Validate a skill's portability
./scripts/convert.sh --validate ./skills/code-guard/

# Check compatibility matrix
./scripts/convert.sh --check ./skills/code-guard/ --platform windsurf
```

## Guardrails

- NEVER publish a skill as "compatible" without testing on the target platform
- ALWAYS include a fallback for platform-specific features
- ALWAYS version your skills semantically in manifest.json
- NEVER silently drop content during conversion — log what was removed
- ALWAYS validate the output of conversion against the target's expected format
- Test edge cases: empty references, missing manifest, platform-specific frontmatter

## Related Skills
- [code-guard](../code-guard/) — Security audit skill built with this standard
