# Contributing to Agent Security Skills

Thank you for your interest in contributing! This guide covers everything you need.

## Development Setup

```bash
# Clone the repo
git clone https://github.com/lanzuanxianggua/agent-security-skills.git
cd agent-security-skills

# Validate the existing skills
./scripts/convert.sh --validate ./skills/code-guard/
./scripts/convert.sh --validate ./skills/portable-skills/

# Test conversion to each platform
./scripts/convert.sh --input ./skills/code-guard/ --target all --output ./test-output/
```

## Skill Structure

Every skill must follow the universal format defined in `skills/portable-skills/`:

```
skill-name/
├── SKILL.md          # Required — skill definition with YAML frontmatter
├── manifest.json     # Required — compatibility & metadata
├── references/       # Optional — supporting documentation
│   └── *.md
└── schemas/          # Optional — output validation schemas
    └── *.json
```

### SKILL.md Requirements

- YAML frontmatter with at least `name` and `description`
- `<default_to_action>` block for immediate behavioral guidance
- Clear "When to Use" section
- Guardrails / safety constraints
- All code examples must be correct and tested

### manifest.json Requirements

- `name`, `version`, `description`, `compatibility` fields
- Compatibility declarations for: claude-code, cursor, windsurf, copilot
- Platform-specific notes for partial/experimental support

## Adding a New Skill

1. Create `skills/<name>/SKILL.md` with universal frontmatter
2. Create `skills/<name>/manifest.json` with compatibility declarations
3. Add reference docs in `skills/<name>/references/`
4. Validate: `./scripts/convert.sh --validate ./skills/<name>/`
5. Test conversion: `./scripts/convert.sh --input ./skills/<name>/ --target all`
6. Update README.md to list the new skill

## Testing

Before submitting a PR:

1. Run validation on your skill
2. Test conversion to at least 2 platforms (e.g., cursor + copilot)
3. Verify the converted output is correct
4. Check that code examples in the skill are syntactically valid
5. Verify no secrets or credentials in your skill files

## Code Style

- Write all content in English
- Use standard Markdown (no HTML except `<default_to_action>` tags)
- Include code examples with correct syntax
- Use kebab-case for file and skill names
- Follow semantic versioning in manifest.json

## Pull Request Process

1. Ensure your PR includes only related changes
2. Update README.md if adding new skills
3. Include manifest.json with all required fields
4. PRs need at least one review before merge
5. Squash commits on merge

## Reporting Issues

Use the GitHub issue templates:
- Bug report: for broken functionality
- Feature request: for new skills or enhancements

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
