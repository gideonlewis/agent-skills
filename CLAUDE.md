# agent-skills

Production-grade engineering skills for Claude Code with personal customization.

## Project Structure

```
skills/<name>/SKILL.md            → Skill content + frontmatter (required)
skills/<name>/agents/openai.yaml  → Codex runtime interface config (required)
skills/<name>/references/         → Checklists, fixtures, metadata snapshots (required)
hooks/                            → Session lifecycle hooks (when needed)
docs/                             → Setup guides and documentation
```

Skills are invoked directly by name (`/plan`, `/spec`, ...). There is no
`.claude/commands/` wrapper layer.

## Skills by Phase

**Define:** Ideation, spec, requirements
**Plan:** Task breakdown, prioritization  
**Build:** Implementation, TDD, incremental development
**Verify:** Testing, debugging, validation
**Review:** Code audit, quality gates, security review
**Ship:** Deployment, documentation, monitoring

## Conventions

### Language

All prose in `SKILL.md` — including the `description` field — is written in
**Vietnamese**. Keep English only for technical keywords (`merge request`,
`pipeline`, `feature flag`), proper nouns (GitLab, Backlog, Mattermost), code
identifiers, and externally mandated templates.

### Skill Format

Every skill lives in `skills/<name>/SKILL.md`. The directory name **must match**
the `name` field:

```yaml
---
name: skill-name
description: >
  Mô tả bằng tiếng Việt: skill làm gì và kích hoạt trong tình huống nào.
---

# Tiêu Đề

## Khi Nào Dùng

Tình huống cụ thể skill này áp dụng, và khi nào nên dùng skill khác.

## Quy Trình

Các bước hoặc phase cụ thể.

## Anti-patterns

Cách làm sai cần tránh.

## Red Flags

🚩 Dấu hiệu đang đi sai hướng.
```

### agents/openai.yaml

Required for every skill. `display_name` and `short_description` are mandatory;
optional properties stay as `#` comments so they are discoverable. Full property
table in [skills/create-skill/references/openai-yaml-properties.md](skills/create-skill/references/openai-yaml-properties.md).

```yaml
interface:
  display_name: "My Skill"
  short_description: "Mô tả ngắn"
  default_prompt: "Dùng $my-skill để ..."
policy:
  allow_implicit_invocation: false
```

### references/

Required directory, with a `README.md` acting as index (or a `TPD` placeholder
when empty). Only split content out to `references/` when it exceeds ~100 lines
or is needed in a subset of situations — keep short content inline in `SKILL.md`.

## Commands

**Installation:**
- `./install.sh` — Interactive picker by default; `--all` installs everything,
  `spec plan build` installs only those, `--list` previews, `-y` skips the
  confirm prompt. The picked set is saved to `.local/config.json` and honored
  by `./sync.sh` afterward.
- `./sync.sh` — Update after git pull (respects a saved custom selection)
- `./status.sh` — Check installation status

**Validation:**
- `./validate-skills.sh` — Check every skill: frontmatter parses, `name` matches
  the directory, `agents/openai.yaml` is valid, `references/` exists

## Boundaries

**Always:**
- Write prose in Vietnamese (keep technical keywords in English)
- Include YAML frontmatter (name, description) with `name` matching the directory
- Include `agents/openai.yaml` and `references/`
- Add "Khi Nào Dùng" section for clarity
- Document anti-patterns and red flags
- Keep skills focused (one workflow per skill)
- Write for repeatability (not one-time advice)

**Never:**
- Commit vague advice ("be thoughtful about...")
- Duplicate content (reference other skills instead)
- Add skills without clear triggering scenario
- Create massive skills (keep under 500 lines)
- Mix multiple unrelated workflows

## Installation

### First Machine
```bash
git clone https://github.com/gideonlewis/agent-skills.git ~/Projects/agent-skills
cd ~/Projects/agent-skills
./install.sh
```

### Other Machines
```bash
cd ~/Projects/agent-skills
git pull
./sync.sh
```

## File Locations

- **Repo:** `~/Projects/agent-skills`
- **Installed Skills:** `~/.claude/skills/` (symlinks)
- **Config:** `~/Projects/agent-skills/.local/config.json`

## References

- [QUICK_START.md](QUICK_START.md) — 30-second guide
- [docs/SETUP.md](docs/SETUP.md) — Installation guide
- [skills/create-skill/SKILL.md](skills/create-skill/SKILL.md) — Skill development (invoke as `/create-skill`)
- [ARCHITECTURE.md](ARCHITECTURE.md) — Technical details

## Inspiration

Based on [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) but optimized for personal use with symlink-based distribution.
