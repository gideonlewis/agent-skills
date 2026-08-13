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

With no arguments, `install.sh` opens an interactive picker so you choose
which skills to install instead of getting all of them:

```
1) ai-platform-gitlab
   Chỉ dùng skill chuyển tiếp này cho implementation evidence trên AI Platform...
2) build
   Xây dựng code theo từng lát cắt task nhỏ (incremental), TDD-first...
...
Chọn skill: 1,3,5-7
```

Other ways to run it:

```bash
./install.sh --all               # install every skill, no prompt
./install.sh spec plan build     # install only these three
./install.sh --list              # preview names + descriptions, install nothing
./install.sh spec plan -y        # skip the confirmation prompt
```

The script will:
- Create `~/.claude/skills` directory
- Symlink only the skills you picked (or all, with `--all`)
- Save your selection to `.local/config.json` — the next `./sync.sh` will
  keep syncing that same subset instead of silently adding every skill back

### Step 3: Verify Installation

```bash
./status.sh
```

You should see the skills you picked listed under "Installed skills".

## Daily Usage

### Creating a New Skill

Full walkthrough (frontmatter, `agents/openai.yaml`, `references/`, Vietnamese
prose convention) lives in the
[create-skill](../skills/create-skill/SKILL.md) skill — invoke it as
`/create-skill`. Short version:

```bash
mkdir -p skills/my-cool-skill/{agents,references}
# write skills/my-cool-skill/SKILL.md, agents/openai.yaml, references/README.md
./validate-skills.sh          # check frontmatter, name match, required files
git add skills/my-cool-skill
git commit -m "Add skill: my-cool-skill"
git push origin main
```

Sync on all machines:
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
  "last_updated": "2026-08-03T07:51:41Z",
  "installation_method": "symlink",
  "selection_mode": "custom",
  "skills_enabled": ["spec", "plan", "build"]
}
```

- **repo_path**: Where you cloned the repository
- **skills_path**: Where symlinks are created
- **machine_name**: Your computer name
- **installation_method**: Always "symlink" for auto-updates
- **selection_mode**: `"all"` if you installed everything, `"custom"` if you
  picked specific skills
- **skills_enabled**: The exact skill names installed on this machine.
  `./sync.sh` reads this to keep only that subset in sync — run
  `./install.sh --all` to go back to installing everything.

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
