# Platform Compatibility Matrix

## Detailed Feature Support

### Claude Code
| Feature | Support | Notes |
|---------|:-------:|-------|
| SKILL.md frontmatter | ✅ Full | All fields supported |
| YAML frontmatter | ✅ Full | Complete YAML parsing |
| `<default_to_action>` | ✅ Full | Loaded as behavioral instructions |
| `references/` directory | ✅ Full | Loaded on demand |
| `schemas/` directory | ✅ Full | Used for output validation |
| `scripts/` directory | ✅ Full | Bash/JSON validation scripts |
| Agent tool calls | ✅ Full | `Agent`, `TaskCreate`, `Skill` |
| Multi-file skills | ✅ Full | Complete directory support |
| Skill discovery | ✅ Full | Auto-discovery from `~/.claude/skills/` |
| Skill invocation | ✅ Full | `/skill-name` command |
| Conditional sections | ✅ Full | `<agent:claude-code>` blocks |
| Install via CLI | ✅ Full | `npx skills add` / symlinks |

### Cursor
| Feature | Support | Notes |
|---------|:-------:|-------|
| SKILL.md frontmatter | ✅ Full | Mapped to MDC format |
| YAML frontmatter | ⚠️ Partial | Mapped to MDC frontmatter |
| `<default_to_action>` | ✅ Full | Rendered as instructions |
| `references/` directory | ⚠️ Partial | Must be inlined during conversion |
| `schemas/` directory | ❌ None | Not supported — dropped |
| `scripts/` directory | ⚠️ Partial | Bash only, no JSON validation |
| Agent tool calls | ⚠️ Partial | Composer-specific tools |
| Multi-file skills | ⚠️ Partial | Converted to single MDC file |
| Skill discovery | ✅ Full | `.cursor/rules/*.mdc` auto-loaded |
| Skill invocation | ✅ Full | Auto-triggered by file context |
| Conditional sections | ❌ None | All sections rendered |
| Install via CLI | ⚠️ Manual | Copy to `.cursor/rules/` |

### Windsurf
| Feature | Support | Notes |
|---------|:-------:|-------|
| SKILL.md frontmatter | ✅ Full | Direct support |
| YAML frontmatter | ✅ Full | Preserved as-is |
| `<default_to_action>` | ✅ Full | Loaded as behavioral rules |
| `references/` directory | ⚠️ Partial | Can be referenced, may need inlining |
| `schemas/` directory | ❌ None | Not supported |
| `scripts/` directory | ⚠️ Partial | Bash only |
| Agent tool calls | ⚠️ Partial | Cascade-specific tools |
| Multi-file skills | ⚠️ Partial | Limited directory support |
| Skill discovery | ✅ Full | `.windsurf/rules/*.md` auto-loaded |
| Skill invocation | ✅ Full | Context-triggered |
| Conditional sections | ❌ None | All sections rendered |
| Install via CLI | ⚠️ Manual | Copy to `.windsurf/rules/` |

### GitHub Copilot
| Feature | Support | Notes |
|---------|:-------:|-------|
| SKILL.md frontmatter | ⚠️ Partial | Stripped to plain Markdown |
| YAML frontmatter | ❌ None | Not parsed — converted to headings |
| `<default_to_action>` | ⚠️ Partial | Rendered as plain text context |
| `references/` directory | ❌ None | Must be inlined |
| `schemas/` directory | ❌ None | Not supported |
| `scripts/` directory | ❌ None | Not supported |
| Agent tool calls | ❌ None | Copilot doesn't support tool calls |
| Multi-file skills | ❌ None | Single flat file |
| Skill discovery | ✅ Full | `.github/copilot-instructions.md` auto-loaded |
| Skill invocation | ✅ Full | Always-on context |
| Conditional sections | ❌ None | All rendered, agent-specific tags ignored |
| Install via CLI | ⚠️ Manual | Append to copilot-instructions.md |

### Aider
| Feature | Support | Notes |
|---------|:-------:|-------|
| SKILL.md frontmatter | ⚠️ Partial | Read as conventions file |
| YAML frontmatter | ❌ None | Not parsed |
| `<default_to_action>` | ✅ Full | Read as instructions |
| `references/` directory | ❌ None | Not supported |
| `schemas/` directory | ❌ None | Not supported |
| `scripts/` directory | ⚠️ Partial | Bash scripts via shell |
| Agent tool calls | ❌ None | Aider has limited tool support |
| Multi-file skills | ❌ None | Single conventions file |
| Skill discovery | ✅ Full | `.aider/` directory auto-loaded |
| Skill invocation | ⚠️ Manual | Via command line flags |
| Conditional sections | ❌ None | All rendered |

## Tool Mapping Reference

### File Operations
| Universal | Claude Code | Cursor | Windsurf | Copilot |
|-----------|-------------|--------|----------|---------|
| Read file | `Read` | `Read` | `Read` | Auto-context |
| Write file | `Write` | `Write` | `Write` | Suggestion |
| Edit file | `Edit` | `Edit` | `Edit` | Suggestion |
| Search files | `Glob` | `Search` | `Search` | Workspace |
| Search content | `Grep` | `Search` | `Search` | Workspace |

### Execution
| Universal | Claude Code | Cursor | Windsurf | Copilot |
|-----------|-------------|--------|----------|---------|
| Run command | `Bash` | `Terminal` | `Terminal` | ❌ |
| Agent dispatch | `Agent` | `Composer` | `Cascade` | ❌ |
| Task tracking | `TaskCreate` | ❌ | ❌ | ❌ |

## Recommended Minimum Viable Skill

For maximum compatibility, a skill should:
1. Have a SKILL.md with only `name` and `description` in frontmatter
2. Use `<default_to_action>` for core behavior
3. Use standard Markdown for all content
4. Include platform-specific sections as clearly marked blocks
5. Not depend on `schemas/`, `scripts/`, or agent-specific tools

This ensures the skill works on ALL platforms, even if some features degrade.
