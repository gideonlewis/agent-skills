# Creating Skills Guide

Learn how to create and share custom Claude Code skills.

## What is a Skill?

A Claude Code skill is a reusable automation or helper that extends Claude Code's capabilities. It can:
- Run scripts or commands
- Provide custom workflows
- Automate repetitive tasks
- Integrate with external tools
- Offer domain-specific helpers

## Skill Anatomy

Each skill folder contains:

```
my-skill/
├── my-skill.plugin.yaml      # Configuration
├── README.md                  # Documentation
├── script.sh                  # Optional: main script
├── config.json                # Optional: configuration
└── assets/                    # Optional: images, templates
    └── icon.png
```

## Step 1: Create Skill Folder

```bash
cd ~/Projects/agent-skills
mkdir skills/my-awesome-skill
cd skills/my-awesome-skill
```

## Step 2: Create Plugin Configuration

Create `my-awesome-skill.plugin.yaml`:

```yaml
name: my-awesome-skill
description: A brief description of what this skill does
version: 1.0.0
author: Your Name
license: MIT

# Trigger patterns that activate this skill
triggers:
  - keyword: "my-keyword"
    description: "What happens when you use this"

# Metadata about the skill
metadata:
  category: "utility"              # utility, ai, automation, integration
  tags: ["productivity", "helper"]
  requires_authentication: false   # Set to true if needs API keys
  supported_platforms:
    - darwin
    - linux
    - win32
  
  # Optional: dependencies
  dependencies:
    - curl
    - jq
  
  # Optional: configuration schema
  config_schema:
    api_key:
      type: string
      description: "API key for this service"
      required: false
```

## Step 3: Create Documentation

Create `README.md`:

```markdown
# My Awesome Skill

Brief description of what this skill does.

## Features

- Feature 1
- Feature 2
- Feature 3

## Usage

How to use this skill.

## Configuration

Any setup or configuration needed.

## Examples

Show usage examples.

## Troubleshooting

Common issues and solutions.
```

## Step 4: Add Implementation (Optional)

If your skill needs executable code, add `script.sh`:

```bash
#!/bin/bash
# My awesome skill implementation

set -e

# Your script here

echo "Skill executed successfully"
```

Don't forget to make it executable:
```bash
chmod +x script.sh
```

## Step 5: Commit to Repository

```bash
cd ~/Projects/agent-skills
git add skills/my-awesome-skill/
git commit -m "Add skill: my-awesome-skill

- What it does
- Key features"
git push origin main
```

## Step 6: Test & Share

### Test on Your Machine
```bash
./sync.sh
./status.sh          # Should show your new skill
```

### Share Across Machines
On other machines:
```bash
cd ~/Projects/agent-skills
git pull
./sync.sh
./status.sh
```

## Skill Categories

Choose one for your skill:

- **utility** - General purpose tools
- **ai** - AI/ML related helpers
- **automation** - Workflow automation
- **integration** - External service integrations
- **productivity** - Productivity boosters
- **development** - Dev tools and helpers

## Best Practices

### 1. One Skill, One Purpose
Each skill should do one thing well. Don't create mega-skills.

### 2. Clear Documentation
Good README = higher chance of use. Include:
- What it does
- How to use it
- Configuration (if any)
- Examples
- Troubleshooting

### 3. Semantic Versioning
Use MAJOR.MINOR.PATCH:
- **1.0.0** → First stable release
- **1.1.0** → New feature added
- **1.0.1** → Bug fix

### 4. Platform Support
Specify which platforms work:
- `darwin` → macOS
- `linux` → Linux
- `win32` → Windows

### 5. Dependency Declaration
List any system dependencies:
```yaml
metadata:
  dependencies:
    - curl           # Required: curl
    - jq             # Required: jq
```

### 6. Error Handling
Scripts should:
```bash
#!/bin/bash
set -e        # Exit on error
set -u        # Exit on undefined variable
set -o pipefail  # Exit on pipe failure
```

### 7. Safe Defaults
```yaml
metadata:
  requires_authentication: false   # Don't require auth unless needed
  destructive: false               # Does it modify files?
  requires_internet: false         # Does it need network?
```

## Example: Real Skill

### Skill: git-status-pretty

```yaml
name: git-status-pretty
description: Display pretty formatted git status across repos
version: 1.0.0
author: Your Name
license: MIT

metadata:
  category: development
  tags: [git, productivity]
  dependencies: [git, awk]
```

### Implementation (git-status-pretty.sh):

```bash
#!/bin/bash
set -e

find ~ -name .git -type d 2>/dev/null | while read git_dir; do
  repo=$(dirname "$git_dir")
  cd "$repo"
  
  status=$(git status --porcelain)
  if [ -n "$status" ]; then
    echo "📁 $repo"
    echo "$status" | awk '{print "   " $0}'
  fi
done
```

## Sharing Your Skills

### Make Public on GitHub
1. Push your repo to GitHub
2. Share the URL: https://github.com/yourusername/agent-skills
3. Others can clone and `./install.sh`

### Version Tracking
- Tag releases: `git tag v1.0.0 && git push --tags`
- Update CHANGELOG.md with changes
- Use semantic versioning

### Getting Feedback
- Open issues in your repo
- Accept pull requests
- Test on multiple machines

## Skill Validation

Before committing, check:

```bash
# Verify YAML syntax
./validate-skills.sh

# Test symlink creation
./sync.sh

# Verify it shows up
./status.sh
```

## Troubleshooting Skill Creation

**Skill not showing up?**
```bash
./install.sh    # Reinstall symlinks
./status.sh     # Check status
```

**Script not executable?**
```bash
chmod +x skills/my-skill/script.sh
git add -A
git commit -m "Make script executable"
```

**YAML syntax error?**
```bash
cat skills/my-skill/my-skill.plugin.yaml | python3 -m yaml.safe_load
```

## Next Steps

1. Create your first skill using this guide
2. Test it on your machine
3. Share with team or GitHub
4. Iterate based on feedback
5. Version bump and tag releases
