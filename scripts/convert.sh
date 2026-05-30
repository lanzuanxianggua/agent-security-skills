#!/usr/bin/env bash
# portable-skills convert — Convert skills between agent platforms
# Usage: ./convert.sh --input <skill-dir> --target <platform> [--output <output-dir>]

set -euo pipefail

VERSION="1.0.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Robust YAML frontmatter parser using awk only.
# Usage: parse_frontmatter <file> <field-name>
# Handles single-quoted, double-quoted, and unquoted values.
# Works on Linux, macOS, and Git Bash (MSYS2/Cygwin).
parse_frontmatter() {
  local file="$1"
  local field="$2"
  awk -v field="$field" '
    # State: 0 = before first ---, 1 = inside frontmatter, 2 = past frontmatter
    /^---[[:space:]]*$/ {
      if (state == 0) { state = 1; next }
      if (state == 1) { state = 2; next }
    }
    state != 1 { next }
    # Only look at lines that start with the target field name (allow leading spaces)
    $0 ~ "^[[:space:]]*" field ":" {
      # Remove leading spaces, the field name, and the colon
      val = $0
      sub("^[[:space:]]*" field ":[[:space:]]*", "", val)
      # Strip surrounding quotes (single or double, matched pair)
      if (val ~ /^".*"$/)  { gsub(/^"/, "", val); gsub(/"$/, "", val) }
      if (val ~ /^'"'"'.*'"'"'$/) { gsub(/^'"'"'/, "", val); gsub(/'"'"'$/, "", val) }
      # Strip any trailing whitespace
      sub(/[[:space:]]+$/, "", val)
      print val
      found = 1
      exit
    }
    { next }
  ' state=0 found=0 "$file"
}

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
  cat <<EOF
portable-skills convert v${VERSION}

Usage:
  $(basename "$0") --input <skill-dir> --target <platform> [--output <dir>]
  $(basename "$0") --validate <skill-dir>
  $(basename "$0") --check <skill-dir> --platform <platform>

Platforms:
  cursor         Cursor (.cursor/rules/*.mdc)
  windsurf       Windsurf (.windsurf/rules/*.md)
  copilot        GitHub Copilot (.github/copilot-instructions.md)
  all            Convert to all platforms above

Options:
  --input DIR     Input skill directory (must contain SKILL.md)
  --target PLAT   Target platform (cursor|windsurf|copilot|all)
  --output DIR    Output directory (default: ./dist/<platform>)
  --validate DIR  Validate a skill's portability
  --check DIR     Check compatibility for a specific platform
  --platform PLAT Platform to check (used with --check)
  --help          Show this help

Examples:
  $(basename "$0") --input ./skills/code-guard/ --target cursor
  $(basename "$0") --input ./skills/code-guard/ --target all --output ./release/
  $(basename "$0") --validate ./skills/code-guard/
EOF
  exit 0
}

# Parse arguments
INPUT=""
TARGET=""
OUTPUT=""
VALIDATE=""
CHECK=""
CHECK_PLATFORM=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)   INPUT="$2"; shift 2 ;;
    --target)  TARGET="$2"; shift 2 ;;
    --output)  OUTPUT="$2"; shift 2 ;;
    --validate) VALIDATE="$2"; shift 2 ;;
    --check)   CHECK="$2"; shift 2 ;;
    --platform) CHECK_PLATFORM="$2"; shift 2 ;;
    --help|-h) usage ;;
    *) log_error "Unknown option: $1"; usage ;;
  esac
done

# Validate skill directory
validate_skill() {
  local dir="$1"
  local errors=0

  if [[ ! -f "$dir/SKILL.md" ]]; then
    log_error "Missing SKILL.md in $dir"
    ((errors++))
  fi

  if [[ ! -f "$dir/manifest.json" ]]; then
    log_warn "Missing manifest.json in $dir (recommended)"
  fi

  # Check SKILL.md has required frontmatter
  if [[ -f "$dir/SKILL.md" ]]; then
    if ! grep -q "^name:" "$dir/SKILL.md"; then
      log_error "SKILL.md missing required 'name' field in frontmatter"
      ((errors++))
    fi
    if ! grep -q "^description:" "$dir/SKILL.md"; then
      log_error "SKILL.md missing required 'description' field in frontmatter"
      ((errors++))
    fi
  fi

  # Check manifest.json has required fields
  if [[ -f "$dir/manifest.json" ]]; then
    if ! command -v jq &>/dev/null; then
      log_warn "jq not installed — manifest.json not fully validated"
      log_warn "Install jq for complete validation: https://stedolan.github.io/jq/"
    else
      for field in name version description compatibility; do
        if ! jq -e ".$field" "$dir/manifest.json" &>/dev/null; then
          log_error "manifest.json missing required field: $field"
          ((errors++))
        fi
      done
    fi
  fi

  # Check for platform-specific content without fallbacks
  if grep -q '<agent:claude-code>' "$dir/SKILL.md" 2>/dev/null; then
    if ! grep -q '<agent:universal>' "$dir/SKILL.md"; then
      log_warn "Claude Code-specific sections found without <agent:universal> fallback"
    fi
  fi

  if [[ $errors -eq 0 ]]; then
    log_ok "Validation passed for $dir"
  else
    log_error "Validation failed with $errors error(s)"
    return 1
  fi
}

# Convert to Cursor MDC format
convert_to_cursor() {
  local input="$1"
  local output="$2"
  local name
  name=$(parse_frontmatter "$input/SKILL.md" "name")

  mkdir -p "$output/.cursor/rules"

  # Extract description from frontmatter
  local desc
  desc=$(parse_frontmatter "$input/SKILL.md" "description")

  # Create MDC file with Cursor frontmatter
  {
    echo "---"
    echo "name: $name"
    echo "description: $desc"
    echo "globs: [\"**/*.{ts,tsx,js,jsx,py,java,go,rs,rb,php,cs}\"]"
    echo "alwaysApply: false"
    echo "---"
    echo ""

    # Extract body (everything after the SECOND --- delimiter)
    # Use awk to properly handle only the first frontmatter block
    awk '/^---$/{n++; next} n>=2{print}' "$input/SKILL.md"

    # Inline references
    if [[ -d "$input/references" ]]; then
      echo ""
      echo "---"
      echo "## References"
      for ref in "$input/references"/*.md; do
        if [[ -f "$ref" ]]; then
          echo ""
          echo "### $(basename "$ref" .md)"
          echo ""
          cat "$ref"
        fi
      done
    fi
  } > "$output/.cursor/rules/${name}.mdc"

  log_ok "Converted to Cursor: $output/.cursor/rules/${name}.mdc"
}

# Convert to Windsurf format
convert_to_windsurf() {
  local input="$1"
  local output="$2"
  local name
  name=$(parse_frontmatter "$input/SKILL.md" "name")

  mkdir -p "$output/.windsurf/rules"

  {
    # Copy SKILL.md as-is (Windsurf supports frontmatter)
    cat "$input/SKILL.md"

    # Inline references
    if [[ -d "$input/references" ]]; then
      echo ""
      echo "---"
      echo "## References"
      for ref in "$input/references"/*.md; do
        if [[ -f "$ref" ]]; then
          echo ""
          echo "### $(basename "$ref" .md)"
          echo ""
          cat "$ref"
        fi
      done
    fi
  } > "$output/.windsurf/rules/${name}.md"

  log_ok "Converted to Windsurf: $output/.windsurf/rules/${name}.md"
}

# Convert to GitHub Copilot format
convert_to_copilot() {
  local input="$1"
  local output="$2"
  local name
  name=$(parse_frontmatter "$input/SKILL.md" "name")
  local desc
  desc=$(parse_frontmatter "$input/SKILL.md" "description")

  mkdir -p "$output/.github"

  # Check for duplicate content
  if [[ -f "$output/.github/copilot-instructions.md" ]] && grep -q "## $name" "$output/.github/copilot-instructions.md" 2>/dev/null; then
    log_warn "Skill '$name' already exists in copilot-instructions.md — appending anyway. Remove duplicates manually if needed."
  fi

  {
    echo "## $name"
    echo ""
    echo "$desc"
    echo ""

    # Extract body (strip frontmatter)
    # Extract body (everything after the SECOND --- delimiter)
    awk '/^---$/{n++; next} n>=2{print}' "$input/SKILL.md"

    # Inline references
    if [[ -d "$input/references" ]]; then
      echo ""
      echo "## References"
      for ref in "$input/references"/*.md; do
        if [[ -f "$ref" ]]; then
          echo ""
          echo "### $(basename "$ref" .md)"
          echo ""
          cat "$ref"
        fi
      done
    fi
  } >> "$output/.github/copilot-instructions.md"

  log_ok "Converted to Copilot: $output/.github/copilot-instructions.md (appended)"
}

# Main logic
if [[ -n "$VALIDATE" ]]; then
  validate_skill "$VALIDATE"
  exit $?
fi

if [[ -n "$CHECK" ]]; then
  if [[ -z "$CHECK_PLATFORM" ]]; then
    log_error "--platform is required with --check"
    exit 1
  fi
  if [[ ! -f "$CHECK/manifest.json" ]]; then
    log_error "No manifest.json found in $CHECK"
    exit 1
  fi
  if command -v jq &>/dev/null; then
    status=$(jq -r ".compatibility.\"$CHECK_PLATFORM\".status // \"unknown\"" "$CHECK/manifest.json")
    notes=$(jq -r ".compatibility.\"$CHECK_PLATFORM\".notes // \"\"" "$CHECK/manifest.json")
    if [[ "$status" == "null" || "$status" == "unknown" ]]; then
      log_error "Unknown platform: $CHECK_PLATFORM"
      log_error "Valid platforms: claude-code, cursor, windsurf, copilot, aider"
      exit 1
    fi
    echo "Platform: $CHECK_PLATFORM"
    echo "Status: $status"
    [[ -n "$notes" ]] && echo "Notes: $notes"
  else
    log_warn "jq not installed — showing raw manifest"
    cat "$CHECK/manifest.json"
  fi
  exit 0
fi

if [[ -z "$INPUT" || -z "$TARGET" ]]; then
  log_error "Both --input and --target are required for conversion"
  exit 1
  usage
fi

if [[ ! -d "$INPUT" ]]; then
  log_error "Input directory does not exist: $INPUT"
  exit 1
fi

# Batch mode: if INPUT has no SKILL.md but has subdirectories with SKILL.md, process all
if [[ ! -f "$INPUT/SKILL.md" ]]; then
  found=0
  for dir in "$INPUT"/*/; do
    if [[ -f "${dir}SKILL.md" ]]; then
      skill_name=$(basename "$dir")
      log_info "Found skill: $skill_name"
      case "$TARGET" in
        cursor) convert_to_cursor "$dir" "$OUTPUT" ;;
        windsurf) convert_to_windsurf "$dir" "$OUTPUT" ;;
        copilot) convert_to_copilot "$dir" "$OUTPUT" ;;
        all)
          convert_to_cursor "$dir" "$OUTPUT"
          convert_to_windsurf "$dir" "$OUTPUT"
          convert_to_copilot "$dir" "$OUTPUT"
          ;;
        *)
          log_error "Unknown target: $TARGET. Use cursor|windsurf|copilot|all"
          exit 1
          ;;
      esac
      found=1
    fi
  done
  if [[ $found -eq 0 ]]; then
    log_error "No SKILL.md found in $INPUT or its subdirectories"
    exit 1
  fi
  log_ok "Batch conversion complete in $OUTPUT"
  exit 0
fi

OUTPUT="${OUTPUT:-./dist}"

case "$TARGET" in
  cursor)
    convert_to_cursor "$INPUT" "$OUTPUT"
    ;;
  windsurf)
    convert_to_windsurf "$INPUT" "$OUTPUT"
    ;;
  copilot)
    convert_to_copilot "$INPUT" "$OUTPUT"
    ;;
  all)
    convert_to_cursor "$INPUT" "$OUTPUT"
    convert_to_windsurf "$INPUT" "$OUTPUT"
    convert_to_copilot "$INPUT" "$OUTPUT"
    log_ok "All conversions complete in $OUTPUT"
    ;;
  *)
    log_error "Unknown target: $TARGET. Use cursor|windsurf|copilot|all"
    exit 1
    ;;
esac
