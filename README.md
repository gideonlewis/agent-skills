# agent-skills

**Production-grade engineering skills for AI coding agents** (personal edition).

Personal skill repository with one-command installation and multi-machine sync. Organized by development lifecycle phases: Define → Plan → Build → Verify → Review → Ship.

```
  DEFINE          PLAN           BUILD          VERIFY         REVIEW          SHIP
 ┌──────┐      ┌──────┐      ┌──────┐      ┌──────┐      ┌──────┐      ┌──────┐
 │ Idea │ ───▶ │ Spec │ ───▶ │ Code │ ───▶ │ Test │ ───▶ │  QA  │ ───▶ │  Go  │
 │Refine│      │  PRD │      │ Impl │      │Debug │      │ Gate │      │ Live │
 └──────┘      └──────┘      └──────┘      └──────┘      └──────┘      └──────┘
  /spec         /plan         /build        /test         /review       /ship
```

## Quick Start

```bash
git clone https://github.com/gideonlewis/agent-skills.git ~/Projects/agent-skills
cd ~/Projects/agent-skills
./install.sh
```

## What is this?

A framework to:
- **Define** engineering workflows as reusable skills
- **Install** with one command across multiple machines
- **Auto-update** instantly when you pull changes
- **Organize** by development phases
- **Share** best practices consistently

## Slash Commands

Eight commands that map to the development lifecycle:

| Command | Phase | Purpose |
|---------|-------|---------|
| `/spec` | DEFINE | Write structured specification |
| `/plan` | PLAN | Break into atomic tasks |
| `/build [task]` | BUILD | Implement incrementally |
| `/test` | VERIFY | Write and run tests |
| `/review` | REVIEW | Audit code quality |
| `/ship` | SHIP | Deploy with documentation |

## Directory Structure

```
skills/
├── example-skill/              # Template skill
│   └── SKILL.md               # Markdown-based skill with detailed instructions
│
agents/
├── code-reviewer.md           # Reusable personas
├── test-engineer.md
└── ...

.claude/commands/
├── spec.md                    # Slash commands
├── plan.md
├── build.md
├── test.md
├── review.md
└── ship.md

references/
├── code-quality-checklist.md  # Supporting checklists
├── security-checklist.md
└── ...
```

## Installation

### First Time
```bash
./install.sh
```

Sets up:
1. `~/.claude/skills/` directory
2. Symlinks to all skills
3. `.local/config.json` (per-machine config)

### Updating All Machines
```bash
cd ~/Projects/agent-skills
git pull
./sync.sh
```

Symlinks auto-update instantly!

## Creating Skills

### Anatomy of a Skill

Each skill is a folder with:
- **SKILL.md** — Core instructions with YAML frontmatter
  ```yaml
  ---
  name: my-skill
  description: What it does. Use when [scenario].
  ---
  # Detailed instructions, phases, anti-patterns
  ```
- **Supporting files** (optional, if content > 100 lines)
  - `examples.md` — Usage examples
  - `criteria.md` — Evaluation rubrics
  - `scripts/` — Automation
  - `references/` — Checklists

### Create a New Skill

```bash
cp -r skills/example-skill skills/my-skill
mv skills/my-skill/SKILL.md skills/my-skill/my-skill.md

# Edit skills/my-skill/my-skill.md
nano skills/my-skill/my-skill.md

# Commit and push
git add skills/my-skill
git commit -m "Add skill: my-skill"
git push
```

## Key Concepts

### SKILL.md Format

Every skill starts with YAML frontmatter:

```yaml
---
name: skill-name
description: What it does. Use when [specific scenario].
---

# Title

Brief overview.

## When to Use

Specific triggering conditions.

## Process

Phases or steps.

## Anti-patterns

What to avoid.

## Red Flags

Watch out for...
```

### Phases

Skills follow development phases:

- **DEFINE** — Ideation, spec, requirements
- **PLAN** — Task breakdown, prioritization
- **BUILD** — Implementation, TDD
- **VERIFY** — Testing, debugging
- **REVIEW** — Code audit, quality gates
- **SHIP** — Deployment, documentation

### Agents

Reusable personas like `code-reviewer`, `test-engineer`, etc.

Use them in skills to delegate specific responsibilities.

## File Locations

| Item | Path |
|------|------|
| Repo | `~/Projects/agent-skills` |
| Skills (source) | `~/Projects/agent-skills/skills/` |
| Skills (symlinks) | `~/.claude/skills/` |
| Commands | `~/.claude/commands/` |
| Config | `~/Projects/agent-skills/.local/config.json` |

## Multi-Machine Setup

**Machine 1 (Primary):**
```bash
git clone https://github.com/gideonlewis/agent-skills.git ~/Projects/agent-skills
cd ~/Projects/agent-skills
./install.sh
```

**Machine 2+:**
```bash
cd ~/Projects/agent-skills
git pull
./sync.sh
```

## Status

Check installation:
```bash
./status.sh
```

## Organization

Skills organized by development phase:

- **Define:** idea-refine, spec-driven-development
- **Plan:** planning-and-task-breakdown
- **Build:** incremental-implementation, test-driven-development
- **Verify:** debugging-and-error-recovery
- **Review:** code-review-and-quality, security-and-hardening
- **Ship:** ci-cd-and-automation, shipping-and-launch

## Documentation

- **[QUICK_START.md](QUICK_START.md)** — 30 seconds
- **[docs/SETUP.md](docs/SETUP.md)** — Full installation
- **[docs/CREATING_SKILLS.md](docs/CREATING_SKILLS.md)** — Skill development
- **[ARCHITECTURE.md](ARCHITECTURE.md)** — Technical overview
- **[CHANGELOG.md](CHANGELOG.md)** — Version history

## Best Practices

### Skill Design

✓ One skill = One workflow (focused)
✓ Clear "When to Use" section
✓ Step-by-step process
✓ Document anti-patterns & red flags
✓ Include supporting materials only if needed

❌ Avoid

✗ Vague instructions
✗ Multiple unrelated workflows
✗ Skipping prerequisites
✗ Over-engineering the process

### Sharing

1. Push to GitHub
2. Document in CLAUDE.md
3. Share repo URL
4. Others: `git clone` + `./install.sh`

## FAQ

**Q: Does git pull auto-update skills?**
A: Yes! Symlinks point to repo. Pull → instant update.

**Q: Can I have machine-specific skills?**
A: Yes, use `.local/config.json` per machine.

**Q: How do I disable a skill?**
A: Remove the symlink: `rm ~/.claude/skills/skill-name`

**Q: Can I mix personal and shared skills?**
A: Yes! Add both to the repo, symlinks work for all.

## License

MIT - see LICENSE file
