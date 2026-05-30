# Migration Guide — Converting Skills Between Platforms

## Claude Code → Cursor (.mdc)

### Conversion Steps

1. **Create MDC file**: Copy SKILL.md content to `.cursor/rules/<name>.mdc`
2. **Convert frontmatter**:
   ```yaml
   # SKILL.md (original)
   ---
   name: code-guard
   description: "Security audit skill"
   triggers:
     cursor:
       - "scan for security issues"
   tags: [security]
   ---

   # .mdc (converted)
   ---
   name: code-guard
   description: Security audit skill
   globs: ["**/*.{ts,tsx,js,jsx,py,java,go,rs}"]
   alwaysApply: false
   ---
   ```
3. **Inline references**: Append content of all `references/*.md` files at the bottom
4. **Strip schemas**: Remove schema references and validation instructions
5. **Simplify tool calls**: Replace Claude Code-specific tools with generic descriptions

### Automated Conversion
```bash
portable-skills convert --from claude-code --to cursor --input ./skills/code-guard/
# Output: .cursor/rules/code-guard.mdc
```

## Claude Code → Windsurf

### Conversion Steps

1. **Create rule file**: Copy to `.windsurf/rules/<name>.md`
2. **Preserve frontmatter**: Keep as YAML comment block at top
3. **Inline references**: Append references into the body
4. **Map triggers**: Add trigger descriptions in "When to Use" section
5. **Keep scripts**: Bash scripts remain usable

```bash
portable-skills convert --from claude-code --to windsurf --input ./skills/code-guard/
# Output: .windsurf/rules/code-guard.md
```

## Claude Code → GitHub Copilot

### Conversion Steps

1. **Append to copilot-instructions.md**: Do NOT overwrite existing content
2. **Strip all frontmatter**: Convert to Markdown heading + first paragraph
3. **Inline everything**: References, examples, all content in one file
4. **Remove tool-specific instructions**: Comment out or remove
5. **Add "When to use" section**: Copilot uses this as implicit trigger

```markdown
## Code Guard — Security Audit

When reviewing code for security issues, scan for OWASP Top 10 vulnerabilities,
leaked secrets, and insecure dependencies.

[... rest of skill body as plain Markdown ...]
```

```bash
portable-skills convert --from claude-code --to copilot --input ./skills/code-guard/
# Output: .github/copilot-instructions.md (appended)
```

## Universal → All Platforms

### Batch Conversion
```bash
# Convert all skills to all platforms
portable-skills convert --input ./skills/ --target all --output ./dist/

# Resulting structure:
# dist/
# ├── claude-code/          # Symlink-ready skill directories
# ├── cursor/               # .cursor/rules/*.mdc files
# ├── windsurf/             # .windsurf/rules/*.md files
# ├── copilot/              # .github/copilot-instructions.md
# └── manifest.json         # Combined compatibility report
```

## Common Conversion Issues

### Issue: Tool references don't map
```
# Original (Claude Code)
await Agent({ prompt: "scan code", subagent_type: "Explore" })

# Fix: Use conditional blocks
<agent:claude-code>
Use the Agent tool to dispatch parallel scans.
</agent:claude-code>

<agent:universal>
For multi-pass scanning, run sequential checks across the codebase.
</agent:universal>
```

### Issue: Schema references in body
```
# Original
Validate output against schemas/output.json

# Fix: Remove schema references for non-Claude Code platforms
# The schema is used for structured output; other platforms produce text output
```

### Issue: Bash scripts not available
```
# Original
Run `scripts/validate.sh` to check results

# Fix: Inline the validation steps
<agent:universal>
To validate results, manually check:
1. All critical findings have fixes
2. No duplicate findings
3. Severity classification follows the guide
</agent:universal>
```

### Issue: Large reference files
```
# Original: references/owasp-top10.md (500+ lines)

# Fix: For platforms without references/ support, create a condensed version
# Include only the detection patterns, not the full explanations
# Link to the full reference in the skill's repository
```

## Testing Converted Skills

After conversion, verify:

1. **Syntax**: No broken Markdown or frontmatter
2. **Completeness**: All sections from the original are present
3. **Functionality**: Trigger conditions work on target platform
4. **Graceful degradation**: No errors from missing features
5. **Content accuracy**: No content lost or garbled in conversion

```bash
# Validate converted skill
portable-skills validate ./dist/cursor/code-guard.mdc --platform cursor

# Check compatibility report
portable-skills report ./skills/code-guard/ --format json
```
