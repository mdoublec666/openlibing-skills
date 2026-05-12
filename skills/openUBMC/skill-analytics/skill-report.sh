#!/usr/bin/env bash
# OpenUBMC Skill Analytics - Session Report Generator
# Analyzes the current AI tool session to generate a usage report.
# Only reads the current session log — never scans historical sessions.
# All data is sanitized: no user input, code, or file paths are collected.

set -euo pipefail

REPORT_VERSION="1.0"
REPORT_FILE="/tmp/skill-report-latest.json"

# --- Tool Detection ---

detect_tool() {
  if [ -n "${OPENCODE:-}" ]; then
    echo "opencode"
  elif [ -n "${CLAUDE_CODE_ENTRYPOINT:-}" ]; then
    echo "claude-code"
  elif [ -d "$HOME/.cursor/skills" ]; then
    echo "cursor"
  else
    echo "unknown"
  fi
}

get_skills_dir() {
  local tool="$1"
  case "$tool" in
    opencode)    echo "$HOME/.config/opencode/skills" ;;
    claude-code) echo "$HOME/.claude/skills" ;;
    cursor)      echo "$HOME/.cursor/skills" ;;
    *)           echo "" ;;
  esac
}

# --- Static Info: Installed Skills ---

collect_installed_skills() {
  local skills_dir="$1"
  local result="[]"

  if [ ! -d "$skills_dir" ]; then
    echo "$result"
    return
  fi

  local items=""
  for dir in "$skills_dir"/*/; do
    [ -d "$dir" ] || continue
    local skill_name
    skill_name=$(basename "$dir")
    [ "$skill_name" = "skill-analytics" ] && continue

    local json_file="$dir/skill.json"
    local version="unknown"
    local installed_days=0

    if [ -f "$json_file" ]; then
      if command -v jq &>/dev/null; then
        version=$(jq -r '.version // "unknown"' "$json_file" 2>/dev/null)
      else
        version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$json_file" 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)"$/\1/' || echo "unknown")
      fi

      if [ "$(uname)" = "Darwin" ]; then
        local file_epoch
        file_epoch=$(stat -f '%m' "$json_file" 2>/dev/null || echo 0)
      else
        local file_epoch
        file_epoch=$(stat -c '%Y' "$json_file" 2>/dev/null || echo 0)
      fi
      local now_epoch
      now_epoch=$(date +%s)
      if [ "$file_epoch" -gt 0 ] 2>/dev/null; then
        installed_days=$(( (now_epoch - file_epoch) / 86400 ))
      fi
    fi

    local item="{\"name\":\"$skill_name\",\"version\":\"$version\",\"installed_days\":$installed_days}"
    if [ -n "$items" ]; then
      items="$items,$item"
    else
      items="$item"
    fi
  done

  echo "[$items]"
}

# --- Current Session Log Location ---

find_current_session_opencode() {
  local db_path="$HOME/.local/share/opencode/opencode.db"
  [ -f "$db_path" ] || return 1
  command -v sqlite3 &>/dev/null || return 1

  # Get the most recently updated session ID
  local session_id
  session_id=$(sqlite3 "$db_path" "SELECT id FROM session ORDER BY time_updated DESC LIMIT 1;" 2>/dev/null)

  [ -n "$session_id" ] && echo "$session_id"
}

find_current_session_log_claude() {
  local projects_dir="$HOME/.claude/projects"
  [ -d "$projects_dir" ] || return 1

  local latest
  latest=$(find "$projects_dir" -name "*.jsonl" -type f -printf '%T@ %p\n' 2>/dev/null \
    | sort -rn | head -1 | awk '{print $2}')

  if [ -z "$latest" ]; then
    latest=$(find "$projects_dir" -name "*.jsonl" -type f 2>/dev/null \
      | xargs ls -t 2>/dev/null | head -1)
  fi

  [ -n "$latest" ] && echo "$latest"
}

find_current_session_log_cursor() {
  local ws_dir="$HOME/.config/Cursor/User/workspaceStorage"
  [ -d "$ws_dir" ] || return 1

  local latest
  latest=$(find "$ws_dir" -name "state.vscdb" -type f -printf '%T@ %p\n' 2>/dev/null \
    | sort -rn | head -1 | awk '{print $2}')

  if [ -z "$latest" ]; then
    latest=$(find "$ws_dir" -name "state.vscdb" -type f 2>/dev/null \
      | xargs ls -t 2>/dev/null | head -1)
  fi

  [ -n "$latest" ] && echo "$latest"
}

# --- Session Log Analysis ---

analyze_opencode_session() {
  local session_id="$1"
  local skills_dir="$2"
  local db_path="$HOME/.local/share/opencode/opencode.db"

  # Query all part data for this session directly from SQLite
  local all_content
  all_content=$(sqlite3 "$db_path" "SELECT data FROM part WHERE session_id = '$session_id';" 2>/dev/null || true)

  if [ -z "$all_content" ]; then
    echo '{"skills_triggered":[],"tool_calls":{},"outcome":"unknown","error_count":0,"failure_cases":[]}'
    return
  fi

  # Extract triggered skills: look for "tool":"skill" entries with skill names
  local triggered_items=""
  local skill_names
  skill_names=$(echo "$all_content" | grep -o '"tool":"skill"' 2>/dev/null || true)

  if [ -n "$skill_names" ]; then
    # Extract actual skill names from input.name fields in skill tool calls
    local found_skills
    found_skills=$(echo "$all_content" | grep '"tool":"skill"' | grep -o '"name":"[^"]*"' | sed 's/"name":"//;s/"//' | sort -u 2>/dev/null || true)

    for sname in $found_skills; do
      # Strip openubmc- prefix to match directory names
      local dir_name
      dir_name=$(echo "$sname" | sed 's/^openubmc-//')
      if [ -n "$triggered_items" ]; then
        triggered_items="$triggered_items,\"$dir_name\""
      else
        triggered_items="\"$dir_name\""
      fi
    done
  fi

  local triggered="[$triggered_items]"

  # Count tool calls by type from part data
  # Use grep -o | wc -l to avoid grep -c multi-line issues
  local bash_count write_count read_count grep_count edit_count
  bash_count=$(echo "$all_content"  | grep -o '"tool":"bash"'  2>/dev/null | wc -l | tr -d ' ')
  write_count=$(echo "$all_content" | grep -o '"tool":"write"' 2>/dev/null | wc -l | tr -d ' ')
  read_count=$(echo "$all_content"  | grep -o '"tool":"read"'  2>/dev/null | wc -l | tr -d ' ')
  grep_count=$(echo "$all_content"  | grep -o '"tool":"grep"'  2>/dev/null | wc -l | tr -d ' ')
  edit_count=$(echo "$all_content"  | grep -o '"tool":"edit"'  2>/dev/null | wc -l | tr -d ' ')

  local tool_calls="{\"bash\":$bash_count,\"write\":$write_count,\"read\":$read_count,\"grep\":$grep_count,\"edit\":$edit_count}"

  # Detect errors from step-finish or tool results
  local error_count
  error_count=$(echo "$all_content" | grep -o '"status":"error"' 2>/dev/null | wc -l | tr -d ' ')

  local outcome="success"
  if [ "$error_count" -gt 3 ]; then
    outcome="fail"
  elif [ "$error_count" -gt 0 ]; then
    outcome="partial"
  fi

  # Build failure_cases (sanitized)
  local failure_cases="[]"
  if [ "$error_count" -gt 0 ] && [ -n "$triggered_items" ]; then
    local first_skill
    first_skill=$(echo "$triggered_items" | head -1 | tr -d '"' | cut -d',' -f1)
    failure_cases="[{\"skill\":\"$first_skill\",\"error_type\":\"tool_execution_error\",\"count\":$error_count}]"
  fi

  cat <<ENDJSON
{"skills_triggered":$triggered,"tool_calls":$tool_calls,"outcome":"$outcome","error_count":$error_count,"failure_cases":$failure_cases}
ENDJSON
}

analyze_claude_session() {
  local session_file="$1"
  local skills_dir="$2"

  local all_content
  all_content=$(cat "$session_file" 2>/dev/null || true)

  extract_from_content "$all_content" "$skills_dir"
}

analyze_cursor_session() {
  local db_file="$1"
  local skills_dir="$2"

  local all_content=""
  if command -v sqlite3 &>/dev/null; then
    all_content=$(sqlite3 "$db_file" "SELECT value FROM ItemTable WHERE key LIKE '%chat%' OR key LIKE '%agent%' LIMIT 50;" 2>/dev/null || true)
  fi

  if [ -z "$all_content" ]; then
    # Cannot read Cursor DB, return minimal report
    echo '{"skills_triggered":[],"tool_calls":{},"outcome":"unknown","error_count":0}'
    return
  fi

  extract_from_content "$all_content" "$skills_dir"
}

# --- Content Extraction (common logic) ---

extract_from_content() {
  local content="$1"
  local skills_dir="$2"

  # Detect triggered skills by searching for skill names in session content
  local triggered="[]"
  local triggered_items=""
  if [ -d "$skills_dir" ]; then
    for dir in "$skills_dir"/*/; do
      [ -d "$dir" ] || continue
      local sname
      sname=$(basename "$dir")
      [ "$sname" = "skill-analytics" ] && continue

      if echo "$content" | grep -qi "$sname" 2>/dev/null; then
        if [ -n "$triggered_items" ]; then
          triggered_items="$triggered_items,\"$sname\""
        else
          triggered_items="\"$sname\""
        fi
      fi
    done
  fi
  triggered="[$triggered_items]"

  # Count tool calls by type (use grep -o | wc -l to avoid multi-line issues)
  local bash_count write_count read_count grep_count edit_count

  bash_count=$(echo "$content"  | grep -oi '"tool"[[:space:]]*:[[:space:]]*"bash"'  2>/dev/null | wc -l | tr -d ' ')
  write_count=$(echo "$content" | grep -oi '"tool"[[:space:]]*:[[:space:]]*"write"' 2>/dev/null | wc -l | tr -d ' ')
  read_count=$(echo "$content"  | grep -oi '"tool"[[:space:]]*:[[:space:]]*"read"'  2>/dev/null | wc -l | tr -d ' ')
  grep_count=$(echo "$content"  | grep -oi '"tool"[[:space:]]*:[[:space:]]*"grep"'  2>/dev/null | wc -l | tr -d ' ')
  edit_count=$(echo "$content"  | grep -oi '"tool"[[:space:]]*:[[:space:]]*"edit"'  2>/dev/null | wc -l | tr -d ' ')

  # Detect errors
  local error_count
  error_count=$(echo "$content" | grep -oi '"status":"error"\|"failed"' 2>/dev/null | wc -l | tr -d ' ')

  local outcome="success"
  if [ "$error_count" -gt 3 ]; then
    outcome="fail"
  elif [ "$error_count" -gt 0 ]; then
    outcome="partial"
  fi

  # Build tool_calls JSON
  local tool_calls="{\"bash\":$bash_count,\"write\":$write_count,\"read\":$read_count,\"grep\":$grep_count,\"edit\":$edit_count}"

  # Build failure_cases (sanitized: only skill name + error type, no content)
  local failure_cases="[]"
  if [ "$error_count" -gt 0 ] && [ -n "$triggered_items" ]; then
    local first_skill
    first_skill=$(echo "$triggered_items" | head -1 | tr -d '"' | cut -d',' -f1)
    failure_cases="[{\"skill\":\"$first_skill\",\"error_type\":\"tool_execution_error\",\"count\":$error_count}]"
  fi

  cat <<ENDJSON
{"skills_triggered":$triggered,"tool_calls":$tool_calls,"outcome":"$outcome","error_count":$error_count,"failure_cases":$failure_cases}
ENDJSON
}

# --- Main ---

main() {
  local tool
  tool=$(detect_tool)

  local skills_dir
  skills_dir=$(get_skills_dir "$tool")

  local os_name
  os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

  # Collect static info
  local installed_skills="[]"
  local total_skills=0
  if [ -n "$skills_dir" ] && [ -d "$skills_dir" ]; then
    installed_skills=$(collect_installed_skills "$skills_dir")
    total_skills=$(echo "$installed_skills" | grep -o '"name"' | wc -l || echo 0)
  fi

  # Find and analyze current session
  local session_data='{"skills_triggered":[],"tool_calls":{},"outcome":"unknown","error_count":0,"failure_cases":[]}'

  case "$tool" in
    opencode)
      local session_id
      session_id=$(find_current_session_opencode 2>/dev/null || true)
      if [ -n "$session_id" ]; then
        session_data=$(analyze_opencode_session "$session_id" "$skills_dir")
      else
        echo "Warning: Could not locate current OpenCode session (sqlite3 required)" >&2
      fi
      ;;
    claude-code)
      local log_file
      log_file=$(find_current_session_log_claude 2>/dev/null || true)
      if [ -n "$log_file" ]; then
        session_data=$(analyze_claude_session "$log_file" "$skills_dir")
      else
        echo "Warning: Could not locate current Claude Code session log" >&2
      fi
      ;;
    cursor)
      local log_file
      log_file=$(find_current_session_log_cursor 2>/dev/null || true)
      if [ -n "$log_file" ]; then
        session_data=$(analyze_cursor_session "$log_file" "$skills_dir")
      else
        echo "Warning: Could not locate current Cursor session log" >&2
      fi
      ;;
    *)
      echo "Warning: Unknown AI tool, only static info will be collected" >&2
      ;;
  esac

  # Extract fields from session_data
  local skills_triggered tool_calls outcome error_count failure_cases
  if command -v jq &>/dev/null; then
    skills_triggered=$(echo "$session_data" | jq -c '.skills_triggered // []')
    tool_calls=$(echo "$session_data" | jq -c '.tool_calls // {}')
    outcome=$(echo "$session_data" | jq -r '.outcome // "unknown"')
    error_count=$(echo "$session_data" | jq -r '.error_count // 0')
    failure_cases=$(echo "$session_data" | jq -c '.failure_cases // []')
  else
    skills_triggered=$(echo "$session_data" | grep -o '"skills_triggered":[^,}]*' | sed 's/"skills_triggered"://' || echo "[]")
    tool_calls=$(echo "$session_data" | grep -o '"tool_calls":{[^}]*}' | sed 's/"tool_calls"://' || echo "{}")
    outcome=$(echo "$session_data" | grep -o '"outcome":"[^"]*"' | sed 's/"outcome":"\([^"]*\)"/\1/' || echo "unknown")
    error_count=$(echo "$session_data" | grep -o '"error_count":[0-9]*' | sed 's/"error_count"://' || echo "0")
    failure_cases=$(echo "$session_data" | grep -o '"failure_cases":\[.*\]' | sed 's/"failure_cases"://' || echo "[]")
  fi

  local generated_at
  generated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Generate final report
  cat > "$REPORT_FILE" <<ENDJSON
{
  "version": "$REPORT_VERSION",
  "generated_at": "$generated_at",
  "scope": "current_session",
  "tool": "$tool",
  "os": "$os_name",
  "static": {
    "installed_skills": $installed_skills,
    "total_skills": $total_skills
  },
  "current_session": {
    "skills_triggered": $skills_triggered,
    "tool_calls": $tool_calls,
    "outcome": "$outcome",
    "error_count": $error_count
  },
  "failure_cases": $failure_cases
}
ENDJSON

  cat "$REPORT_FILE"
}

main "$@"
