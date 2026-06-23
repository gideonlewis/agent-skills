# agent-skills

Production-grade engineering skills for Claude Code with personal customization.

## Project Structure

```
skills/              → Core skills (SKILL.md per directory)
agents/              → Reusable agent personas (code-reviewer, test-engineer, etc.)
references/          → Checklists and evaluation criteria
.claude/commands/    → Slash commands (/spec, /plan, /build, /test, /review, /ship)
hooks/              → Session lifecycle hooks (when needed)
docs/               → Setup guides and documentation
```

## Skills by Phase

**Define:** Ideation, spec, requirements
**Plan:** Task breakdown, prioritization  
**Build:** Implementation, TDD, incremental development
**Verify:** Testing, debugging, validation
**Review:** Code audit, quality gates, security review
**Ship:** Deployment, documentation, monitoring

## Conventions

### Skill Format

Every skill lives in `skills/<name>/SKILL.md` with frontmatter:

```yaml
---
name: skill-name
description: What it does. Use when [specific scenario].
---

# Title

## When to Use

When this skill applies.

## Process

Step-by-step phases or instructions.

## Anti-patterns

What to avoid.

## Red Flags

🚩 Watch out for...
```

### Supporting Files

Only create if content exceeds 100 lines:
- `examples.md` — Concrete usage examples
- `criteria.md` — Evaluation rubrics  
- `scripts/` — Automation scripts
- `references/` — Checklists

### Slash Commands

Commands in `.claude/commands/` invoke skills:

```markdown
---
description: What this command does
---

# /command-name

When invoked, activate [skill-name].

Process:
1. Step 1
2. Step 2
3. Output artifact
```

### Agents

Reusable personas in `agents/` for delegation:

- `code-reviewer.md` — Code quality audits
- `test-engineer.md` — Test strategy and coverage
- Add custom agents for your workflow

## Commands

**Installation:**
- `./install.sh` — Initial setup (creates symlinks)
- `./sync.sh` — Update after git pull
- `./status.sh` — Check installation status

**Validation:**
- Verify all SKILL.md files have valid YAML frontmatter
- Verify name and description fields present
- Verify "When to Use" section is specific (not vague)

## Boundaries

**Always:**
- Include YAML frontmatter (name, description)
- Add "When to Use" section for clarity
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
- [docs/CREATING_SKILLS.md](docs/CREATING_SKILLS.md) — Skill development
- [ARCHITECTURE.md](ARCHITECTURE.md) — Technical details

## Inspiration

Based on [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) but optimized for personal use with symlink-based distribution.
