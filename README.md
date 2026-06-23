# agent-skills

Personal skill repository for Claude Code with one-command installation and multi-machine sync.

## Quick Start

```bash
git clone https://github.com/yourusername/agent-skills.git ~/Projects/agent-skills
cd ~/Projects/agent-skills
./install.sh
```

## What is this?

A centralized repository to:
- **Create & organize** custom Claude Code skills
- **Install with one command** across multiple machines
- **Auto-update** when you pull new changes
- **Track versions** and manage dependencies

## Directory Structure

```
skills/
├── skill-name-1/          # Each skill in its own folder
│   ├── skill-name-1.plugin.yaml
│   └── README.md
└── skill-name-2/
    ├── skill-name-2.plugin.yaml
    └── README.md
```

## Installation

### First Time Setup
```bash
./install.sh
```

This will:
1. Create `~/.claude/skills` directory if needed
2. Set up symlinks to all skills in this repo
3. Save installation metadata

### Updating Skills
```bash
git pull
./sync.sh
```

### Per-Machine Configuration
Create `.local/config.json` for machine-specific settings:
```json
{
  "machine_name": "my-laptop",
  "skills_enabled": ["skill-1", "skill-2"],
  "installation_date": "2026-06-23"
}
```

## Creating a New Skill

1. Create a folder under `skills/`:
```bash
mkdir skills/my-new-skill
cd skills/my-new-skill
```

2. Create `my-new-skill.plugin.yaml`:
```yaml
name: my-new-skill
description: What this skill does
version: 1.0.0
author: Your Name
```

3. Add documentation in `README.md`

4. Commit and push:
```bash
git add skills/my-new-skill
git commit -m "Add skill: my-new-skill"
git push
```

## File Locations

- **Repo**: `~/Projects/agent-skills` (or wherever you clone it)
- **Symlinks**: `~/.claude/skills/` → points to repo skills
- **Config**: `~/.claude/skills/.local/config.json`

## Status

Check which skills are installed:
```bash
./status.sh
```

## FAQ

**Q: Does updating the repo auto-update my skills?**
A: Only if you use symlinks (default). Just `git pull` in the repo directory.

**Q: Can I customize skills per machine?**
A: Yes, edit `.local/config.json` to enable/disable skills per machine.

**Q: How do I share skills with others?**
A: Push your skills repo to GitHub, others clone and run `install.sh`.

## License

MIT - see LICENSE file
