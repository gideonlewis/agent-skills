# Architecture - Agent Skills

Complete technical overview of how the agent-skills system works.

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Repository                         │
│              ~/Projects/agent-skills                         │
└─────────────────────────────────────────────────────────────┘
         ↓ git clone / git pull
┌─────────────────────────────────────────────────────────────┐
│                  Local Repository                            │
│    ~/Projects/agent-skills/skills/ (source files)           │
└─────────────────────────────────────────────────────────────┘
         ↓ install.sh / sync.sh (creates symlinks)
┌─────────────────────────────────────────────────────────────┐
│                   Symlink Targets                            │
│     ~/.claude/skills/ (what Claude Code reads)              │
└─────────────────────────────────────────────────────────────┘
         ↓ Claude Code loads
┌─────────────────────────────────────────────────────────────┐
│                    Claude Code                               │
│           (CLI, Desktop, Web, Extensions)                   │
└─────────────────────────────────────────────────────────────┘
```

## Key Design Decisions

### 1. Symlink-Based Distribution

**Why?**
- Instant updates: `git pull` updates skills immediately
- No manual reinstallation needed
- Single source of truth (repo is the source)
- Minimal storage overhead

**How?**
```bash
# Source
~/Projects/agent-skills/skills/my-skill/

# Symlink
~/.claude/skills/my-skill -> ~/Projects/agent-skills/skills/my-skill/
```

### 2. Per-Machine Configuration

**Why?**
- Track installation state per machine
- Allow different skill sets on different machines
- Don't pollute repo with machine-specific files

**How?**
- `.local/config.json` is in `.gitignore`
- Each machine gets its own config on installation
- Config tracks: machine name, install date, repo path, etc.

### 3. Simple Shell Scripts

**Why?**
- No dependencies (no Node.js, Python, Go required)
- Works on macOS, Linux, Windows (WSL)
- Easy to understand and modify
- Fast execution

**Files:**
- `install.sh` - Initial setup (4 steps)
- `sync.sh` - Update after git pull
- `status.sh` - Check current state

### 4. Single Responsibility

**Install:**
- Creates directories
- Builds symlinks
- Saves config

**Sync:**
- Removes broken links
- Recreates symlinks
- Silent operation

**Status:**
- Shows current state
- Validates symlinks
- Reports machine info

## File Structure

```
agent-skills/
├── skills/                          # Source skills
│   ├── example-skill/               # Template skill
│   │   ├── example-skill.plugin.yaml  # Configuration
│   │   └── README.md                # Documentation
│   └── [user skills here]
│
├── scripts/                         # (Optional) reusable scripts
│   └── [shared utilities]
│
├── docs/                            # Documentation
│   ├── SETUP.md                     # Installation guide
│   └── CREATING_SKILLS.md           # Skill development
│
├── .local/                          # Machine-specific (git-ignored)
│   └── config.json                  # Per-machine config
│
├── install.sh                       # Initial setup script
├── sync.sh                          # Update script
├── status.sh                        # Check status script
├── README.md                        # Overview
├── QUICK_START.md                   # 30-second guide
├── CHANGELOG.md                     # Version history
└── LICENSE                          # MIT License
```

## Skill File Structure

Each skill is self-contained:

```
my-skill/
├── my-skill.plugin.yaml             # Required: Configuration
│   ├── name                         # Unique identifier
│   ├── description                  # What it does
│   ├── version                      # Semantic version
│   ├── author                       # Creator
│   ├── triggers                     # How to invoke (optional)
│   └── metadata                     # Tags, dependencies, etc.
│
├── README.md                        # Required: Documentation
│   ├── Description
│   ├── Features
│   ├── Usage
│   └── Troubleshooting
│
├── script.sh                        # Optional: Implementation
├── config.json                      # Optional: Default config
└── assets/                          # Optional: Icons, templates
    └── icon.png
```

## Multi-Machine Synchronization

### Machine A (Primary)
```bash
~/Projects/agent-skills/
├── skills/my-skill/              # Edit and create
git commit -m "Add skill: my-skill"
git push origin main
```

### Machine B (Secondary)
```bash
cd ~/Projects/agent-skills
git pull                           # Get new skill
./sync.sh                          # Update symlinks
# That's it! Skill is now available
```

### Key Insight
Symlinks point to repo files, so `git pull` automatically updates all machines.

## Configuration Management

### `.local/config.json` (per-machine, git-ignored)

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

Created by `install.sh`, tracks:
- Where repo is cloned
- Where skills are installed
- When installation happened
- What installation method was used

## Update Workflow

### Step 1: Create New Skill
```bash
mkdir skills/new-skill
# Create .plugin.yaml and README.md
git add skills/new-skill
git commit -m "Add skill: new-skill"
git push
```

### Step 2: Update on Other Machines
```bash
cd ~/Projects/agent-skills
git pull                    # Downloads new-skill folder
./sync.sh                   # Creates symlink
./status.sh                 # Verify
```

### Zero-Copy Magic
- New skill code is in the repo
- Symlink points to it
- Claude Code immediately sees it
- No installation or copying needed

## Versioning Strategy

Use semantic versioning in `plugin.yaml`:

```yaml
version: 1.2.3
         ↓  ↓  ↓
      MAJOR.MINOR.PATCH
```

- **MAJOR** (1.0.0 → 2.0.0) - Breaking changes
- **MINOR** (1.0.0 → 1.1.0) - New features
- **PATCH** (1.0.0 → 1.0.1) - Bug fixes

Track in CHANGELOG.md:
```markdown
## [1.2.0] - 2026-06-25
### Added
- New feature X
### Fixed
- Bug Y
```

## Security Considerations

### What's Tracked in Git
- Skill code and configuration
- Documentation
- Public assets (icons, templates)

### What's NOT Tracked (`.gitignore`)
- `.local/config.json` - Machine-specific
- `.env` - Secrets (don't commit!)
- Node/Python dependencies
- IDE settings

### Best Practices
- Don't commit API keys to YAML files
- Store secrets in environment variables
- Use `.env.local` (git-ignored) for testing
- Document which env vars skills need

## Scaling Considerations

### Performance
- Symlink creation: ~1ms per skill
- Install script: <1 second for 100 skills
- Sync script: <100ms on most machines

### Limits
- No practical limit on number of skills
- Works with single-skill repos and 1000+ skill repos
- Compatible with nested directories (not used)

### Team Sharing
Multiple approaches:
1. **Shared GitHub repo** - Everyone clones and installs
2. **Org-wide repo** - Central management
3. **Personal repos** - Merge to central on release

## Extensibility

The system is intentionally simple to allow customization:

### Add Private Skills
```bash
mkdir skills/internal-only
# Don't push to GitHub
```

### Add Local Scripts
```bash
scripts/
├── install-deps.sh
├── validate-skills.sh
└── backup-config.sh
```

### Override on Machine
```bash
.local/
├── config.json
├── disabled-skills.txt
└── machine-overrides.sh
```

## Comparison with Alternatives

| Feature | agent-skills | NPM | GitHub | Homebrew |
|---------|---|---|---|---|
| Setup | 1 cmd | 1 cmd | 3+ steps | 1 cmd |
| Multi-machine | Yes | Yes | Yes | Yes |
| Update speed | Instant | 10s | Instant | 10s+ |
| Dependencies | None | Node | Git | Brew |
| Works offline | Yes | No | No | No |
| Custom skills | Easy | Hard | Hard | Very hard |
| Learning curve | 5min | 10min | 15min | 20min |

## Future Enhancements (Optional)

Not implemented, but easy to add:

- Skill disable/enable per machine
- Dependency resolution
- Automatic backup before sync
- Web dashboard for status
- CI/CD for skill validation
- Community skill marketplace

## Troubleshooting Architecture

### Symlinks Not Working?
Check: `ls -la ~/.claude/skills/`

Should show: `my-skill -> /path/to/repo/skills/my-skill`

If missing: Run `./install.sh`

### Stale Symlinks?
Check: `./status.sh`

Look for: `✗ skill-name (broken link)`

Fix: `./sync.sh`

### Slow Updates?
Symlinks are instant. Slowness is likely:
- Network (git clone/pull)
- Claude Code reloading
- Filesystem indexing

## File Location Reference

| Item | Path | Created by |
|------|------|-----------|
| Repository | `~/Projects/agent-skills` | User (git clone) |
| Skills source | `~/Projects/agent-skills/skills/` | User (create skill) |
| Skills installed | `~/.claude/skills/` | install.sh |
| Symlinks | `~/.claude/skills/skill-name` | install.sh/sync.sh |
| Config | `~/.claude/skills/.local/config.json` | install.sh |
| Claude Code | `~/Library/Application Support/Claude/` | Claude Code |

---

This architecture prioritizes simplicity, reliability, and ease of use over features.
