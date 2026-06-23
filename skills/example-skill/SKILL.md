---
name: example-skill
description: Example skill template for building custom engineering workflows. Use when creating new skills to encapsulate repeatable best practices and automate engineering processes.
---

# Example Skill

A template for building custom engineering skills that encode workflows, processes, and best practices.

## When to Use

- You want to create a reusable workflow or process
- You need to automate an engineering task consistently
- You want to share a skill across multiple projects or machines

## Skill Anatomy

Every skill should have:

1. **SKILL.md** (this file)
   - YAML frontmatter with `name` and `description`
   - Clear instructions on when and how to use
   - Step-by-step process or phases
   - Anti-patterns and red flags

2. **Supporting files** (optional, only if content > 100 lines)
   - `examples.md` - Concrete usage examples
   - `criteria.md` - Evaluation rubrics
   - `scripts/` - Automation scripts
   - `references/` - Supporting checklists

## Process

### Phase 1: Understand the Requirements

When invoked, ask clarifying questions to understand:
- What problem does this solve?
- Who is this for?
- What success looks like
- Any constraints or dependencies

### Phase 2: Execute the Skill

Follow your documented process:
- Break work into discrete steps
- Make progress visible
- Validate at each stage

### Phase 3: Verify & Document

Ensure:
- Output matches requirements
- Process is repeatable
- Document learnings for next time

## Anti-patterns to Avoid

- ❌ Vague or prescriptive instructions
- ❌ Assuming context the user doesn't have
- ❌ Skipping the "when to use" section
- ❌ Mixing multiple unrelated workflows
- ❌ Forgetting the user might have constraints you don't

## Red Flags

🚩 If the skill is:
- Longer than 500 lines → Split into smaller skills
- Trying to do too many things → Focus on one workflow
- Not repeatable → Add more structure and clarity
- Unclear when to invoke → Better "When to Use" section

## How to Create Your Own Skill

1. Copy this folder:
   ```bash
   cp -r skills/example-skill skills/your-skill
   ```

2. Update SKILL.md:
   ```yaml
   ---
   name: your-skill
   description: What your skill does. Use when [specific scenario].
   ---
   ```

3. Define your process with phases

4. Add supporting files if needed

5. Commit and push:
   ```bash
   git add skills/your-skill
   git commit -m "Add skill: your-skill"
   git push
   ```

## Examples

See `examples.md` if provided for real-world usage examples.

## Verification

To verify your skill is working:
- [ ] Clear SKILL.md with frontmatter
- [ ] "When to Use" section is specific
- [ ] Process is step-by-step and repeatable
- [ ] Supporting files only if needed
