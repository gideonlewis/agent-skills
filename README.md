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

## Skills

32 skills trong `skills/`. Mô tả lấy từ `short_description` trong `agents/openai.yaml` — khi thêm hoặc sửa skill, cập nhật bảng này.

### Lifecycle

| Skill | Mô tả |
|---|---|
| [`spec`](skills/spec/SKILL.md) | Viết specification trước khi code |
| [`plan`](skills/plan/SKILL.md) | Chia spec thành task list có ưu tiên |
| [`build`](skills/build/SKILL.md) | Implement từng task theo hướng TDD |
| [`test`](skills/test/SKILL.md) | Verify code bằng test coverage |
| [`review`](skills/review/SKILL.md) | Audit chất lượng code trước khi merge |
| [`ship`](skills/ship/SKILL.md) | Chuẩn bị và deploy lên production |

### spc-collab / azuki

| Skill | Mô tả |
|---|---|
| [`azuki-app-feature-flag-cleanup`](skills/azuki-app-feature-flag-cleanup/SKILL.md) | Gỡ feature flag đã rollout xong khỏi frontend azuki-app (Phase 1 của xoá 2 pha) |
| [`azuki-core-api-backlog-task`](skills/azuki-core-api-backlog-task/SKILL.md) | Rã chunk Core API migration thành BE Task Backlog và viết description (Solution, RPC info, Expected, Evidence) |
| [`azuki-core-api-migration-pr`](skills/azuki-core-api-migration-pr/SKILL.md) | Soạn title/description tiếng Anh từ migration report, tạo PR, gắn label semver |
| [`azuki-core-api-proto-migration-workflow`](skills/azuki-core-api-proto-migration-workflow/SKILL.md) | Branch → proto → commit/push → PR → review cho một batch Console RPC hoặc PR follow-up |
| [`azuki-core-api-proto-migration-workflow-v2`](skills/azuki-core-api-proto-migration-workflow-v2/SKILL.md) | Migrate 1 Console RPC sang Core proto với core.entity riêng, giữ type Console, 1 RPC 1 PR, đăng ký core_service theo lô |
| [`azuki-feature-flag-cleanup-pr-description`](skills/azuki-feature-flag-cleanup-pr-description/SKILL.md) | Viết PR description cho cleanup feature flag backend azuki, có mục Scope ảnh hưởng bắt buộc |
| [`azuki-feature-flag-cleanup-verify`](skills/azuki-feature-flag-cleanup-verify/SKILL.md) | Double-check việc xoá feature flag ở azuki/azuki-app trước khi mở PR hoặc khi review PR |
| [`azuki-feature-flag-implementation`](skills/azuki-feature-flag-implementation/SKILL.md) | Triển khai feature flag phía repo azuki |
| [`azuki-feature-flag-proto-implementation`](skills/azuki-feature-flag-proto-implementation/SKILL.md) | Thêm field feature flag vào cred-proto |
| [`azuki-kinako-ui-adapter`](skills/azuki-kinako-ui-adapter/SKILL.md) | Tạo adapter Vibe→Kinako cho một component trong azuki-app |
| [`azuki-migrate-console-rpc-to-core-proto`](skills/azuki-migrate-console-rpc-to-core-proto/SKILL.md) | Phân tích Console RPC, viết proto Core theo mẫu chunk_1, xuất migration report |
| [`azuki-review-console-rpc-to-core-proto`](skills/azuki-review-console-rpc-to-core-proto/SKILL.md) | Đối chiếu PR migrate Console RPC sang Core proto với Console gốc và code azuki thật |
| [`cred-proto-git`](skills/cred-proto-git/SKILL.md) | Tạo branch (mới / follow-up stacked trên PR), commit, push an toàn trong cred-proto |
| [`github-review-requests`](skills/github-review-requests/SKILL.md) | List PR open ở azuki/azuki-app/cred-proto theo đối tượng (team, tôi, từng thành viên) hoặc 1 repo, xuất Markdown cho Mattermost |
| [`spc-collab-calendar`](skills/spc-collab-calendar/SKILL.md) | Đặt lịch họp cho dự án spc-collab theo nhóm DEV/PO/BrSE/QC |
| [`spc-collab-report`](skills/spc-collab-report/SKILL.md) | Viết report/summary đồng nhất cho dự án spc-collab lên Mattermost/Slack/Jira |

### AI Platform & công cụ

| Skill | Mô tả |
|---|---|
| [`ai-platform-gitlab`](skills/ai-platform-gitlab/SKILL.md) | Lấy implementation evidence từ GitLab |
| [`code-review`](skills/code-review/SKILL.md) | Review MR/PR trên AI Platform GitLab |
| [`knowledge-search`](skills/knowledge-search/SKILL.md) | Tra cứu tri thức nội bộ AI Platform |
| [`nulab-backlog`](skills/nulab-backlog/SKILL.md) | Quản lý vòng đời ticket Backlog |
| [`google-calendar`](skills/google-calendar/SKILL.md) | Đặt và điều phối lịch họp TEQ |
| [`web-search`](skills/web-search/SKILL.md) | Tìm kiếm web qua TEQ AI Gateway |

### HTML artifact

| Skill | Mô tả |
|---|---|
| [`html`](skills/html/SKILL.md) | Tạo HTML artifact độc lập, chỉn chu |
| [`html-diagram`](skills/html-diagram/SKILL.md) | Trực quan hóa kiến trúc bằng sơ đồ SVG |
| [`html-plan`](skills/html-plan/SKILL.md) | Tạo trang plan HTML thực dụng |

### Meta

| Skill | Mô tả |
|---|---|
| [`create-skill`](skills/create-skill/SKILL.md) | Tạo và chuẩn hóa skill mới |
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
- **[skills/create-skill/SKILL.md](skills/create-skill/SKILL.md)** — Skill development (invoke as `/create-skill`)
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
