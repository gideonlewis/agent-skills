# Quick Start - Agent Skills

**TL;DR** - Get up and running in 30 seconds.

## Installation (First Time)

```bash
cd ~/Projects/agent-skills
./install.sh
./status.sh
```

Done! All skills are now available in Claude Code.

## Creating a New Skill

```bash
# Copy template
cp -r skills/example-skill skills/my-skill

# Edit configuration
nano skills/my-skill/my-skill.plugin.yaml

# Commit
git add skills/my-skill
git commit -m "Add skill: my-skill"
git push
```

## Updating on Other Machines

```bash
cd ~/Projects/agent-skills
git pull
./sync.sh
```

That's it! Symlinks auto-update your skills everywhere.

## Common Commands

| Command | What it does |
|---------|-------------|
| `./install.sh` | Initial setup |
| `./sync.sh` | Update after `git pull` |
| `./status.sh` | Check what's installed |
| `git pull && ./sync.sh` | Get latest skills |

## Directory Structure

```
~/Projects/agent-skills/          ← Clone here
├── skills/
│   ├── example-skill/            ← Template
│   └── my-skill/                 ← Your skill
├── install.sh                    ← Run once
├── sync.sh                       ← Run after git pull
└── status.sh                     ← Check status

~/.claude/skills/                 ← Claude Code looks here
├── example-skill → ~/Projects/...  ← Symlinks
└── my-skill → ~/Projects/...
```

## File Locations

| What | Where |
|------|-------|
| Skills repo | `~/Projects/agent-skills` |
| Skills (symlinks) | `~/.claude/skills/` |
| Config | `~/Projects/agent-skills/.local/config.json` |
| Docs | `~/Projects/agent-skills/docs/` |

## Troubleshooting

**Skills not showing?**
```bash
./install.sh
```

**Broken symlinks?**
```bash
./sync.sh
./status.sh
```

**Want to uninstall?**
```bash
rm -rf ~/.claude/skills
rm -rf ~/Projects/agent-skills
```

## Next Steps

- Read [SETUP.md](docs/SETUP.md) for full installation guide
- Read [CREATING_SKILLS.md](docs/CREATING_SKILLS.md) to learn skill development
- Create your first skill!

## Support

- Check `./status.sh` for current state
- See docs/ folder for detailed guides
- Review example-skill as a template
