---
name: spcc-feature-flag-cleanup-pr-description
description: Write the PR title and description for a backend (azuki) feature-flag-cleanup PR — Phase 2 removal of a flag definition after its azuki-app references were already removed and deployed, or removal of a backend-only flag that was never exposed to the frontend. Produces a mandatory "影響範囲" (scope of impact) bullet list summarizing which handlers/scenarios/shared libraries the removed branch touched and how wide the blast radius is, plus a link to the original feature rollout PR/ticket. Use when writing or updating the description of a `cleanup-feature-flag` (azuki) PR, or when reviewing such a PR and finding its description is missing scope-of-impact information.
---

# Writing PR descriptions for azuki feature-flag cleanup (backend)

## Goal

A feature-flag-cleanup PR doesn't add a feature — it deletes a branch and locks in whichever path was already enabled. The one thing a reviewer cannot get from the diff alone is **how wide the blast radius is**: is this a self-contained handler, or does it touch a shared library called from a dozen unrelated places? That's exactly what this skill's mandatory `### 影響範囲` (scope of impact) section exists to make explicit.

Real precedent for the gap this fills: `Finatext/azuki#14549` (`enable_offset_pagination` removal) touched 4 Console API handlers, 1 core_hook scenario, 2 core_task CSV-export scenarios, **and** `internal/lib/query_service/find_ids.go` — a shared function called from many domains — but its description was two generic bullets ("keep the enabled flow", "remove obsolete references") with no mention of which callers are affected or that the removed branch was the *only* thing standing between id-based and business-date-based sort ordering. A reviewer reading only that description could not tell this touches shared code without opening the diff.

## Language

Default to Japanese, matching `.github/pull_request_template.md`'s `## 概要` / `## 参考リンク` headings — this is what most merged cleanup PRs use (e.g. `Finatext/azuki#14531`, a 4-flag cleanup, uses this exact template). English bodies do exist in the repo (e.g. `#14549`) and are tolerated, but they are not the convention to default to. If the user hasn't said which language, ask; otherwise write Japanese.

Field names, RPC/flag names, and file paths stay in their original form (not translated).

## Required input

- The flag(s) being removed: snake_case key(s) (e.g. `enable_offset_pagination`) and the Go variable name (e.g. `EnableOffsetPagination`)
- Whether this is:
  - **Phase 2** of a two-phase removal (the flag was exposed to azuki-app; its frontend references were removed and deployed first) — need the Phase 1 PR link
  - a **backend-only** removal (the flag was never exposed to the frontend) — no Phase 1 PR to link, just the original feature rollout PR/ticket
- The full diff or file list of the cleanup change
- JIRA ticket if one exists (azuki does not enforce a `CRES-#####` regex on PR titles the way cred-proto's `pr-title-jira-check.yml` does, but including it is still the convention when a ticket exists)

Missing the file list → the `影響範囲` section cannot be written responsibly. Go get the diff; don't infer scope from the flag name alone.

## Template

```markdown
## 概要

`<flag_key>` フィーチャーフラグは全ライセンシー・全環境で有効化され安定しているため、azuki (バックエンド) から定義を削除します。

<!-- Phase 2 の場合のみ、この1文を入れる -->
これは 2段階削除の Phase 2 です。azuki-app 側の参照削除 (Phase 1) は #<PR番号> で完了・本番デプロイ済みです。

### 削除したフラグ

- `<flag_key>`（`<PascalCase変数名>`）

### 影響範囲

- <エリア1（ハンドラー/シナリオ/共通ライブラリ名）> — <呼び出し元にとって何が変わるか>
- <エリア2> — <同上>
- **影響範囲: <狭い/中程度/広い>** — <その判断理由>

### 変更ファイル

| ファイル | 内容 |
|---|---|
| `<path>` | <このファイルで何をしたか、一言> |

## 参考リンク

- <元のロールアウトPR、または Phase 1 PR へのリンク>
- <JIRAチケットへのリンク（あれば）>
```

## Rules for `### 影響範囲` (mandatory, this is the point of this skill)

One bullet per **affected area**, grouped by where the removed branch's code lived — not one bullet per file. Merge files that serve the same handler/scenario into a single bullet.

For each bullet, state two things:

1. **The area**: a Console/Core API handler, a `core_hook_scenario`, a `core_task_scenario`, or a shared library function — name it, don't just say "several files".
2. **What locks in for callers**: the removed branch chose between two behaviors; state which one is now permanent and, if relevant, what's lost (e.g. "no more fallback to id-desc sort for cursor pagination — offset pagination is now the only mode").

Then always close with exactly one blast-radius classification bullet:

| Classification | When |
|---|---|
| 狭い (narrow) | Touches 1-2 handlers only, nothing under `internal/lib/` |
| 中程度 (medium) | Touches a handful of handlers/scenarios in the same domain |
| 広い (wide) | Touches anything under `internal/lib/` (or another cross-domain shared package) — call this out explicitly, since a shared function's callers are not all visible in the diff |

Worked example, reconstructed from actually reviewing `Finatext/azuki#14549`:

```markdown
### 影響範囲

- Console API の一覧系ハンドラー4つ（`GetBorrowerLoanSummaries`, `GetEmploymentVerificationRequests`, `GetReviewRequests`, `GetTransfers`）— ソート順が `id desc` から業務日時カラム desc（`requested_at desc` 等）に固定される。フラグ無効時に使っていた id ベースのソートには戻せなくなる
- `core_hook_scenario` の再鑑却下フロー（`employment_verification.go`）— 直前の EmploymentVerificationRequest 取得時のソートも同様に固定される
- `core_task_scenario` の CSV export 2種（`export_borrowers`, `export_overdue_borrowers_csv`）— 出力順が同様に固定される
- 共通ライブラリ `internal/lib/query_service/find_ids.go`（`FindIDs`）— ID一覧取得の全呼び出し元に影響する共通関数。offset pagination 分岐が常時有効になる
- **影響範囲: 広い** — `FindIDs` は複数ドメインから呼ばれる共通関数のため、diff に現れる呼び出し元以外にも間接的な影響がないか確認すること
```

### How to determine this without guessing

Don't eyeball the file list and guess. Do this instead:

1. `grep -rn "<FlagVarName>\|<flag_key>"` across the whole repo on the branch **before** your change lands, to see every call site the flag gated (not just the ones in the diff you were handed — someone may have already trimmed the diff).
2. For each file touched, check its path: anything under `internal/lib/` is cross-domain shared code by construction — treat it as `広い` by default. `internal/presentation/` and `internal/scenario/` are single-handler/single-domain by construction unless the function itself is exported and reused (check callers with `grep`).
3. After the change lands (or on the PR branch), re-run the same grep to confirm zero leftover references — this is also part of the quality gate for the cleanup itself, not just the description.
4. For anything that changes observable behavior (sort order, response shape, error codes), name the specific behavior in the bullet — "cleans up legacy code" is not a scope-of-impact statement, it's a non-statement.

## `### 変更ファイル`

A short table, one row per file, one line each — not a prose paragraph. This mirrors what merged PRs in this repo already do for non-flag changes (e.g. `Finatext/azuki#14529`'s "変更ファイル" section), so reuse that convention rather than inventing a new one.

## `## 参考リンク`

- **Phase 2 removal**: link the Phase 1 PR (the one that removed azuki-app's references) — without it, a reviewer has no way to confirm Phase 1 actually shipped before this PR deletes the flag.
- **Backend-only removal**: link the original feature rollout PR or the JIRA ticket that introduced the flag.
- Either way, an empty `## 参考リンク` section (as seen in `#14549`) is a gap — don't ship one.

## Relationship with `create-pull-request` and azuki's own `cleanup-feature-flag` skill

This skill only produces **content** (title + body text). The actual code removal is done by azuki's own `.claude/skills/cleanup-feature-flag/SKILL.md` (Phase 2 backend procedure); creating the PR itself is done by the `create-pull-request` skill.

Handoff:

- Write the body to a file, hand the path to `create-pull-request` with `--body-file` — never `--body` inline, the body has a markdown table and multiple headings that are easy to mangle inline.
- Don't let `create-pull-request` auto-generate `## 概要` from `git diff` — that loses the `影響範囲` section, which is the entire point.
- Azuki's PR title convention includes the JIRA ticket when one exists (`[CRES-#####] <description>` or `CRES-##### <description>` — both forms appear in merged history), but there is no CI regex enforcing it the way cred-proto does. Still include it when available.

## Checklist before submitting

- [ ] Body is written in Japanese (unless the user explicitly asked for English)
- [ ] `### 削除したフラグ` lists every flag removed in this PR, snake_case and PascalCase
- [ ] `### 影響範囲` has one bullet per affected area (not per file), each naming what locks in for callers
- [ ] `### 影響範囲` ends with exactly one 狭い/中程度/広い classification bullet, with a stated reason
- [ ] Any file under `internal/lib/` (or other shared package) is called out and the classification reflects it
- [ ] `### 変更ファイル` covers every changed file
- [ ] `## 参考リンク` links the Phase 1 PR (if Phase 2) or the original rollout PR/ticket (if backend-only) — never left empty
- [ ] Confirmed zero leftover references to the removed flag (`grep -rn` across the whole repo), and said so
