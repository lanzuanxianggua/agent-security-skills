#!/usr/bin/env bats
# Tests for scripts/convert.sh
# Run: bats tests/convert.bats

setup() {
  export REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  export CONVERT="${REPO_ROOT}/scripts/convert.sh"
  export TEST_DIR="$(mktemp -d)"
  export DIST_DIR="${TEST_DIR}/dist"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# ─── parse_frontmatter ─────────────────────────────────────────────

@test "parse_frontmatter extracts name from SKILL.md" {
  run bash -c "source '$CONVERT'; parse_frontmatter '${REPO_ROOT}/skills/code-guard/SKILL.md' name"
  [ "$output" = "code-guard" ]
}

@test "parse_frontmatter extracts description from SKILL.md" {
  run bash -c "source '$CONVERT'; parse_frontmatter '${REPO_ROOT}/skills/code-guard/SKILL.md' description"
  [ ${#output} -gt 10 ]
}

@test "parse_frontmatter handles unquoted values" {
  echo -e "---\nname: test-skill\n---" > "${TEST_DIR}/SKILL.md"
  run bash -c "source '$CONVERT'; parse_frontmatter '${TEST_DIR}/SKILL.md' name"
  [ "$output" = "test-skill" ]
}

@test "parse_frontmatter handles double-quoted values" {
  echo -e "---\nname: \"test-skill\"\n---" > "${TEST_DIR}/SKILL.md"
  run bash -c "source '$CONVERT'; parse_frontmatter '${TEST_DIR}/SKILL.md' name"
  [ "$output" = "test-skill" ]
}

@test "parse_frontmatter handles single-quoted values" {
  echo -e "---\nname: 'test-skill'\n---" > "${TEST_DIR}/SKILL.md"
  run bash -c "source '$CONVERT'; parse_frontmatter '${TEST_DIR}/SKILL.md' name"
  [ "$output" = "test-skill" ]
}

@test "parse_frontmatter strips trailing whitespace" {
  echo -e "---\nname: test-skill   \n---" > "${TEST_DIR}/SKILL.md"
  run bash -c "source '$CONVERT'; parse_frontmatter '${TEST_DIR}/SKILL.md' name"
  [ "$output" = "test-skill" ]
}

@test "parse_frontmatter returns empty for missing field" {
  echo -e "---\nname: test-skill\n---" > "${TEST_DIR}/SKILL.md"
  run bash -c "source '$CONVERT'; parse_frontmatter '${TEST_DIR}/SKILL.md' nonexistent"
  [ "$output" = "" ]
}

# ─── validate_skill ─────────────────────────────────────────────────

@test "validate passes for code-guard" {
  run bash "$CONVERT" --validate "${REPO_ROOT}/skills/code-guard/"
  [ "$status" -eq 0 ]
}

@test "validate passes for portable-skills" {
  run bash "$CONVERT" --validate "${REPO_ROOT}/skills/portable-skills/"
  [ "$status" -eq 0 ]
}

@test "validate fails when SKILL.md is missing" {
  mkdir -p "${TEST_DIR}/empty-skill"
  run bash "$CONVERT" --validate "${TEST_DIR}/empty-skill/"
  [ "$status" -ne 0 ]
}

@test "validate fails when name field is missing" {
  mkdir -p "${TEST_DIR}/bad-skill"
  echo -e "---\ndescription: \"no name field\"\n---" > "${TEST_DIR}/bad-skill/SKILL.md"
  run bash "$CONVERT" --validate "${TEST_DIR}/bad-skill/"
  [ "$status" -ne 0 ]
}

@test "validate warns when manifest.json is missing" {
  mkdir -p "${TEST_DIR}/no-manifest"
  echo -e "---\nname: test\ndescription: \"test skill\"\n---" > "${TEST_DIR}/no-manifest/SKILL.md"
  run bash "$CONVERT" --validate "${TEST_DIR}/no-manifest/"
  echo "$output" | grep -q "manifest.json"
}

# ─── --check ────────────────────────────────────────────────────────

@test "check shows status for cursor" {
  run bash "$CONVERT" --check "${REPO_ROOT}/skills/code-guard/" --platform cursor
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "cursor"
}

@test "check shows status for windsurf" {
  run bash "$CONVERT" --check "${REPO_ROOT}/skills/code-guard/" --platform windsurf
  [ "$status" -eq 0 ]
}

@test "check fails for unknown platform" {
  run bash "$CONVERT" --check "${REPO_ROOT}/skills/code-guard/" --platform nonexistentxyz
  [ "$status" -ne 0 ]
  echo "$output" | grep -qi "unknown"
}

@test "check fails when manifest.json is missing" {
  mkdir -p "${TEST_DIR}/no-manifest-check"
  echo -e "---\nname: test\ndescription: \"test\"\n---" > "${TEST_DIR}/no-manifest-check/SKILL.md"
  run bash "$CONVERT" --check "${TEST_DIR}/no-manifest-check/" --platform cursor
  [ "$status" -ne 0 ]
}

# ─── Conversion ─────────────────────────────────────────────────────

@test "convert to cursor creates .mdc file" {
  run bash "$CONVERT" --input "${REPO_ROOT}/skills/code-guard/" --target cursor --output "$DIST_DIR"
  [ "$status" -eq 0 ]
  [ -f "${DIST_DIR}/.cursor/rules/code-guard.mdc" ]
}

@test "cursor output contains MDC frontmatter" {
  bash "$CONVERT" --input "${REPO_ROOT}/skills/code-guard/" --target cursor --output "$DIST_DIR"
  run cat "${DIST_DIR}/.cursor/rules/code-guard.mdc"
  echo "$output" | grep -q "^---$"
  echo "$output" | grep -q "name: code-guard"
}

@test "convert to windsurf creates .md file" {
  run bash "$CONVERT" --input "${REPO_ROOT}/skills/code-guard/" --target windsurf --output "$DIST_DIR"
  [ "$status" -eq 0 ]
  [ -f "${DIST_DIR}/.windsurf/rules/code-guard.md" ]
}

@test "convert to copilot creates copilot-instructions.md" {
  run bash "$CONVERT" --input "${REPO_ROOT}/skills/code-guard/" --target copilot --output "$DIST_DIR"
  [ "$status" -eq 0 ]
  [ -f "${DIST_DIR}/.github/copilot-instructions.md" ]
}

@test "copilot output contains skill heading" {
  bash "$CONVERT" --input "${REPO_ROOT}/skills/code-guard/" --target copilot --output "$DIST_DIR"
  run cat "${DIST_DIR}/.github/copilot-instructions.md"
  echo "$output" | grep -q "## code-guard"
}

@test "convert to all creates all three outputs" {
  run bash "$CONVERT" --input "${REPO_ROOT}/skills/code-guard/" --target all --output "$DIST_DIR"
  [ "$status" -eq 0 ]
  [ -f "${DIST_DIR}/.cursor/rules/code-guard.mdc" ]
  [ -f "${DIST_DIR}/.windsurf/rules/code-guard.md" ]
  [ -f "${DIST_DIR}/.github/copilot-instructions.md" ]
}

@test "batch mode converts all skills in directory" {
  run bash "$CONVERT" --input "${REPO_ROOT}/skills/" --target all --output "$DIST_DIR"
  [ "$status" -eq 0 ]
}

# ─── Error handling ────────────────────────────────────────────────

@test "exit code non-zero on missing arguments" {
  run bash "$CONVERT"
  [ "$status" -ne 0 ]
}

@test "exit code non-zero on missing --target" {
  run bash "$CONVERT" --input "${REPO_ROOT}/skills/code-guard/"
  [ "$status" -ne 0 ]
}

@test "--help shows usage text" {
  run bash "$CONVERT" --help
  echo "$output" | grep -q "portable-skills convert"
}

@test "error on nonexistent input directory" {
  run bash "$CONVERT" --input "/nonexistent/path/" --target cursor
  [ "$status" -ne 0 ]
}
