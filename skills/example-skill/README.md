# Example Skill

This is a template for creating your own Claude Code skills.

## Structure

Each skill folder contains:
- `skill-name.plugin.yaml` - Skill configuration and metadata
- `README.md` - Documentation for your skill

## Creating Your Own Skill

1. **Copy this folder:**
```bash
cp -r skills/example-skill skills/my-new-skill
```

2. **Rename the YAML file:**
```bash
mv skills/my-new-skill/example-skill.plugin.yaml \
   skills/my-new-skill/my-new-skill.plugin.yaml
```

3. **Edit the YAML file** with your skill details

4. **Commit and push:**
```bash
git add skills/my-new-skill
git commit -m "Add skill: my-new-skill"
git push
```

5. **Sync on all machines:**
```bash
./sync.sh
```

## Skill YAML Structure

```yaml
name: skill-name                    # Unique identifier
description: What it does           # Brief description
version: 1.0.0                      # Semantic versioning
author: Your Name                   # Author name

triggers:                           # Optional: activation triggers
  - keyword: "trigger-word"
    description: "What it does"

metadata:
  category: "category"              # utility, ai, automation, etc.
  requires_authentication: false    # If it needs credentials
  supported_platforms:              # What OSes
    - darwin
    - linux
    - win32
```

## Tips

- Keep skills focused and single-purpose
- Use semantic versioning (MAJOR.MINOR.PATCH)
- Document edge cases in README
- Test on multiple machines before committing

## Examples

See other skill folders for real examples of how to structure your skills.
