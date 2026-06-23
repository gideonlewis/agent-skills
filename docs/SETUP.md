# Setup Guide - Agent Skills

Complete guide to setting up agent-skills on your machine.

## Prerequisites

- Git installed
- Claude Code (CLI or Desktop)
- Bash shell
- ~5 minutes ⏱️

## Installation Steps

### Step 1: Clone the Repository

```bash
# Choose a location (suggested: ~/Projects)
cd ~/Projects
git clone https://github.com/yourusername/agent-skills.git
cd agent-skills
```

### Step 2: Run Installation

```bash
chmod +x install.sh sync.sh status.sh
./install.sh
```

The script will:
- Create `~/.claude/skills` directory
- Set up symlinks to all skills in the repo
- Create `.local/config.json` with your machine details

### Step 3: Verify Installation

```bash
./status.sh
```

You should see:
```
✓ Installed skills:
  ✓ example-skill
```

## Daily Usage

### Creating a New Skill

1. **Copy the template:**
```bash
cp -r skills/example-skill skills/my-cool-skill
mv skills/my-cool-skill/example-skill.plugin.yaml \
   skills/my-cool-skill/my-cool-skill.plugin.yaml
```

2. **Edit the YAML file:**
```bash
nano skills/my-cool-skill/my-cool-skill.plugin.yaml
```

3. **Commit to git:**
```bash
git add skills/my-cool-skill
git commit -m "Add skill: my-cool-skill"
git push origin main
```

4. **Sync on all machines:**
```bash
./sync.sh
```

### Updating Skills Across Machines

On any machine:
```bash
cd ~/Projects/agent-skills
git pull                  # Get latest changes
./sync.sh                # Update symlinks
./status.sh              # Verify
```

Since we use symlinks, you get instant updates!

## Multi-Machine Setup

### First Machine
```bash
git clone https://github.com/yourusername/agent-skills.git ~/Projects/agent-skills
cd ~/Projects/agent-skills
./install.sh
```

### Second Machine (Laptop, Work Computer, etc.)
```bash
# Same setup
cd ~/Projects/agent-skills
git pull
./sync.sh
```

The `.local/config.json` is per-machine, so each computer tracks its own installation metadata.

## Understanding the Configuration

Check your `.local/config.json`:

```json
{
  "repo_path": "/Users/name/Projects/agent-skills",
  "skills_path": "/Users/name/.claude/skills",
  "machine_name": "my-laptop",
  "installation_date": "2026-06-23T15:30:00Z",
  "installation_method": "symlink",
  "skills_enabled": []
}
```

- **repo_path**: Where you cloned the repository
- **skills_path**: Where symlinks are created
- **machine_name**: Your computer name
- **installation_method**: Always "symlink" for auto-updates

## Troubleshooting

### Symlinks not working?
```bash
# Check if links are valid
cd ~/.claude/skills
ls -la

# Reinstall
cd ~/Projects/agent-skills
./install.sh
```

### Skills not showing up?
```bash
# Verify directory exists
ls -la ~/.claude/skills

# Force resync
./sync.sh
./status.sh
```

### Want to uninstall?
```bash
cd ~/.claude/skills
rm -rf *              # Remove all symlinks
cd ~/Projects
rm -rf agent-skills   # Remove repo (optional)
```

## File Locations Quick Reference

| Item | Location |
|------|----------|
| Repository | `~/Projects/agent-skills` |
| Skills source | `~/Projects/agent-skills/skills/` |
| Installed skills | `~/.claude/skills/` (symlinks) |
| Config | `~/Projects/agent-skills/.local/config.json` |
| Scripts | `./install.sh`, `./sync.sh`, `./status.sh` |

## Next Steps

1. Run `./status.sh` to verify installation
2. Create your first custom skill
3. Test it with Claude Code
4. Push to GitHub for team sharing
5. Set up automatic syncs on your other machines
