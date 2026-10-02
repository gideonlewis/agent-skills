---
name: spcc-feature-flag-cleanup-verify
description: Verify that a feature-flag cleanup was done correctly — in azuki (backend, Go) or azuki-app (frontend, TypeScript), either on your own working tree before opening a PR, or on someone else's PR fetched into a throwaway worktree. Checks completeness (no leftover references anywhere in the repo), correctness (the ENABLED branch survived, not the disabled one), dead code left behind, build/lint/test with a pre-existing-failure baseline comparison, and two-phase removal ordering. Use before opening a flag-cleanup PR, when reviewing one, or when a cleanup PR's CI/test results look ambiguous.
argument-hint: "flag name, and optionally a PR number to review (e.g. enable_some_feature, or enable_some_feature #14549)"
---

# Verifying a feature-flag cleanup

## Why this skill exists

A flag cleanup is a **deletion** change, and its dangerous failure mode is not a crash — it is **silently keeping the wrong branch**. `if enabled { A } else { B }` reduced to `B` compiles, passes lint, passes every existing test, and ships a behavior regression that nobody notices until a user reports it.

So "it builds and tests pass" is **not** verification. The checks below are ordered by what they actually catch, with the semantic check (Layer 2) being the one no tool performs for you.

## Input

- The flag name — snake_case key (`enable_some_feature`) and/or the code symbol (Go `EnableSomeFeature`, TS `enableSomeFeature`)
- Optionally a PR number to review instead of the local working tree

## Mode A — verify the local working tree (before opening a PR)

Work directly in the repo. Confirm first what is actually staged/modified:

```bash
git status --short
git diff --stat
```

## Mode B — review someone else's PR

Never check the PR out over your own working tree. Fetch it into a throwaway worktree:

```bash
git fetch origin pull/<N>/head:pr-<N>-check
git worktree add /tmp/pr-<N>-check pr-<N>-check
```

Clean up when done — this is not optional, a stale worktree blocks later branch operations:

```bash
git worktree remove /tmp/pr-<N>-check --force
git branch -D pr-<N>-check
```

Also pull the PR's own CI verdict. `statusCheckRollup` mixes two shapes — `CheckRun` uses `name`/`conclusion`, `StatusContext` uses `context`/`state` — so a naive filter prints `null` rows and hides failures. Normalize both:

```bash
gh pr view <N> --json statusCheckRollup \
  --jq '.statusCheckRollup[] | {name: (.name // .context), conclusion: (.conclusion // .state)}'
```

---

## Layer 1 — Completeness: nothing left behind

Grep the **whole repo**, not just the files in the diff. The diff you were handed may be partial, and test mocks / proto / generated wiring live far from the handler that was edited.

Both spellings, since the key and the symbol differ:

```bash
# azuki (backend)
rg -n "EnableSomeFeature|enable_some_feature" --glob '!vendor' .

# azuki-app (frontend)
rg -n "enableSomeFeature|enable_some_feature" src
```

Expected result: **zero hits**. Any hit is a finding, including in comments and test files.

Places that are easy to miss:

| Repo | Easy-to-miss location |
|---|---|
| azuki | `internal/presentation/*/get_feature_flags/handler.go` (4–5 presentation layers) |
| azuki | `feature_mock.WithGlobalOverride(flag.X, ...)` inside `_test.go` |
| azuki | `.proto` field in `GetFeatureFlagsResponse` (cred-proto — Phase 2 only) |
| azuki-app | `src/models/menu.ts` conditional spread, `src/plugins/router.tsx` route guard |
| azuki-app | `vi.mock('@/hooks/useFeatureFlags')` in `*.spec.*` |

## Layer 2 — Correctness: did the ENABLED branch survive?

This is the check that matters most and the only one you must reason about rather than run.

**Step 1 — find out which path was actually live in production.** Read the flag definition as it existed *before* the cleanup:

```bash
git show origin/master:internal/lib/feature/flag/<file>.go | rg -A 12 "EnableSomeFeature"
```

Look at `feature.WithDefault(...)` and any `.ForEnv(...)`. A flag being cleaned up should have been fully rolled out — the live path is the **enabled/true** branch. If the definition says otherwise (default false everywhere, no override), stop: the flag may not actually be rolled out and the cleanup is premature.

**Step 2 — for every removed branch, confirm the survivor.** Read the diff hunk by hunk. For each `if enabled { A } else { B }` that disappeared, the remaining code must be `A`.

Worked example from a real PR (`azuki#14549`, `enable_offset_pagination`):

```go
// before
sort := tentity.GMOTransferSortIDDesc          // disabled path
if enableOffsetPagination {
    sort = tentity.GMOTransferSortRequestedAtDesc   // enabled path
}
```

The correct result keeps `GMOTransferSortRequestedAtDesc`. Keeping `GMOTransferSortIDDesc` would compile, lint, and pass tests — while silently reverting every affected list's sort order in production. Four handlers, a core_hook scenario and two CSV exports all had this same shape in that one PR.

**Step 3 — watch for inverted conditions.** A gate written as `if !enabled { return legacy(...) }` means the *early return* is the dead path; the code after it survives. Read the polarity, do not pattern-match.

**Step 4 — behavior notes worth flagging even when correct.** If the surviving path changes something observable (sort order, response shape, a field that is now always present), say so in the review — it belongs in the PR's scope-of-impact section even though the code is right.

## Layer 3 — Dead code left behind

Removing the branch often orphans the code that only the branch used.

**azuki** has a dedicated check for exactly this:

```bash
make lint/go/deadcode
```

It reports unreachable functions minus `.deadcodeignore`. This is what catches a leftover `getFeatureFlagEnableSomeFeature(ctx, lid) bool` helper whose only caller was the removed branch. The same check runs in CI as `deadcode`.

**azuki-app** has no equivalent for unused *exported* components — eslint only catches unused imports and locals:

```bash
pnpm lint:eslint
```

So also grep by name for anything the disabled path owned:

```bash
rg -n "LegacyForm|OldXxx" src     # components only rendered when the flag was off
```

Typical orphans in both repos: a `getFeatureFlagXxx` helper, a `LegacyXxx`/`OldXxx` component, sort/field-mask constants referenced only by the dead branch, i18n keys used only by the old UI, and a now-unused `props` field (e.g. a boolean prop that existed solely to pass the flag value down — if the caller stopped passing it, the prop should be gone from the component too).

## Layer 4 — Build / lint / test, against a baseline

Run the checks — but **both repos currently carry pre-existing failures**, so a raw red result proves nothing on its own.

```bash
# azuki
go build ./...
go test ./internal/<touched-pkgs>/...     # or: make dev/test for everything
make lint/go/diff-only                    # lints only dirs changed vs origin/master

# azuki-app
pnpm tsc
pnpm lint:eslint
pnpm test:unit:ci
```

**The baseline technique — use it whenever anything is red.** Stash the change, re-run the same command, compare, restore:

```bash
git stash
pnpm test:unit:ci   # or: go test ./...
git stash pop
```

If the failing set is byte-for-byte the same before and after, the failures are pre-existing and the cleanup is clean. Record the exact numbers in your report, e.g. *"8 test files / 4 tests fail — identical before and after, all in `platformFeatureFlags` + `contract.spec.ts`, caused by a stale local cred-proto"*. Without this, a reviewer reasonably concludes the cleanup broke the build.

For Mode B (worktree), stash does not apply — compare against the base branch instead by running the same command on `origin/master` in a second worktree, or simply check whether the failures touch any file in the PR's diff.

## Layer 5 — Two-phase ordering (FE-exposed flags only)

If the flag was exposed to the frontend, backend removal (Phase 2) is only safe **after** the azuki-app removal (Phase 1) is merged *and deployed to production*. Merged is not enough — an old client still in a user's browser will receive `false` and fall back to the dead path.

```bash
gh pr view <FE PR number> --repo Finatext/azuki-app --json state,mergedAt,title
```

If the flag was never exposed (backend-only), this layer does not apply — say so explicitly rather than leaving it unanswered.

## Layer 6 — Parent/child flag ordering

Some flags come in families where one gates the feature and another gates a sub-option of it (for example an export RPC plus the individual transfer types it can emit). The **child must be removed no later than the parent** — removing the parent first leaves the child gating code that can no longer be reached in a meaningful state.

If the flag under review has siblings, check the sibling's status before approving:

```bash
rg -n "enable_sibling_flag" .
```

## Report format

Report findings as a short list, each with the layer it came from and whether it blocks:

```text
Flag: enable_some_feature (azuki, Phase 2)

✅ Layer 1 completeness — 0 references repo-wide (both spellings)
✅ Layer 2 correctness — 7 branches removed, enabled path survived in all
                         (spot-checked get_transfers, export_borrowers)
❌ Layer 3 dead code   — getFeatureFlagEnableSomeFeature() now unreachable
                         (make lint/go/deadcode), remove it
✅ Layer 4 build/test  — build ok; 4 tests fail, identical before/after (pre-existing)
⚠️  Layer 5 two-phase  — FE PR #3033 merged but deploy not confirmed — ask before merging
n/a Layer 6            — no sibling flags

Blocking: Layer 3. Non-blocking: Layer 5 needs a yes/no from the deployer.
```

Never report a pre-existing failure as a finding without saying it is pre-existing and how you proved it.

## Quality gates

- Grep run over the whole repo, not the diff, for both spellings — 0 hits
- Every removed branch checked for which side survived, against the flag's pre-cleanup default
- Dead-code check run (`make lint/go/deadcode` in azuki; name-grep in azuki-app)
- Any red build/lint/test result either explained by a baseline comparison or reported as a real break
- Two-phase ordering answered explicitly (confirmed, or n/a for backend-only)
- Mode B worktree removed and its branch deleted

## Related skills

- `spcc-app-feature-flag-cleanup` — performing the Phase 1 (frontend) removal
- `azuki/.claude/skills/cleanup-feature-flag/SKILL.md` — performing the Phase 2 (backend) removal
- `spcc-feature-flag-cleanup-pr-description` — writing the PR description, including the scope-of-impact section this skill's Layer 2 findings feed into
