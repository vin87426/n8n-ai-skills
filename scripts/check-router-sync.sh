#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

catalog="route-repo-skills/references/skill-catalog.md"
router_dir="route-repo-skills/"

if [[ ! -f "$catalog" ]]; then
  echo "ERROR: missing router catalog: $catalog" >&2
  exit 1
fi

inventory_file="$(mktemp)"
catalog_file="$(mktemp)"
trap 'rm -f "$inventory_file" "$catalog_file"' EXIT

for skill_file in */SKILL.md; do
  skill_dir="${skill_file%%/*}"
  [[ "$skill_dir" == "route-repo-skills" ]] && continue

  skill_name="$(awk '
    /^name:[[:space:]]*/ {
      sub(/^name:[[:space:]]*/, "")
      print
      exit
    }
  ' "$skill_file")"

  if [[ -z "$skill_name" ]]; then
    echo "ERROR: missing name in $skill_file" >&2
    exit 1
  fi

  if [[ "$skill_dir" != "$skill_name" ]]; then
    echo "ERROR: skill directory $skill_dir does not match name $skill_name" >&2
    exit 1
  fi

  printf '%s\n' "$skill_name" >> "$inventory_file"
done

sed -n 's/^## `\([^`]*\)`$/\1/p' "$catalog" > "$catalog_file"
sort -u -o "$inventory_file" "$inventory_file"
sort -u -o "$catalog_file" "$catalog_file"

if ! diff -u "$inventory_file" "$catalog_file"; then
  echo "ERROR: router catalog does not match repo skill inventory." >&2
  exit 1
fi

router_metadata="route-repo-skills/agents/openai.yaml"
if [[ ! -f "$router_metadata" ]] || ! grep -Fqx '  allow_implicit_invocation: true' "$router_metadata"; then
  echo "ERROR: router must set policy.allow_implicit_invocation to true." >&2
  exit 1
fi

while IFS= read -r skill_name; do
  target_metadata="$skill_name/agents/openai.yaml"
  if [[ ! -f "$target_metadata" ]] || ! grep -Fqx '  allow_implicit_invocation: false' "$target_metadata"; then
    echo "ERROR: target $skill_name must set policy.allow_implicit_invocation to false." >&2
    exit 1
  fi
done < "$inventory_file"

mapfile -t staged_files < <(git diff --cached --name-only --diff-filter=ACMRD)

contract_changed=false
router_changed=false

for path in "${staged_files[@]}"; do
  if [[ "$path" == "$router_dir"* ]]; then
    router_changed=true
    continue
  fi

  case "$path" in
    */SKILL.md|*/agents/openai.yaml)
      contract_changed=true
      ;;
    */references/*)
      echo "NOTICE: review whether $path changes routing inputs or boundaries." >&2
      ;;
  esac
done

if [[ "$contract_changed" == true && "$router_changed" != true ]]; then
  echo "ERROR: staged skill contract changed without a staged route-repo-skills update." >&2
  exit 1
fi

echo "Router catalog and staged contract sync checks passed."
