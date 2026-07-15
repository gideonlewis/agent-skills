---
name: implement-feature-flag
description: |
  End-to-end workflow for implementing a new feature flag across cred-proto and azuki.
  Use when asked to "add / implement a feature flag", expose a flag to the frontend
  via GetFeatureFlags, or wire a new flag into a get_feature_flags handler.
  Covers both frontend-facing flags (proto + PR + handler + definition) and
  backend-only flags (definition + feature.Flag() usage only).
argument-hint: "[azuki-only | both] <flag name / purpose>"
---

# Implement a Feature Flag (cred-proto + azuki)

This skill implements a **new** feature flag from scratch. For general best
practices (naming, override precedence, delete-friendly code, tests) defer to the
`use-feature-flag` skill (azuki project skill) — this skill focuses on the
concrete **step-by-step wiring** across the two repos.

## Argument: pick the scope up front

Read the invocation argument to decide **which steps to run** without asking again:

| Argument (aliases) | Scope | Steps to run |
| --- | --- | --- |
| `azuki-only`, `be-only`, `backend`, `azuki` | Backend-only flag | **4 → 6 only** (skip proto & PR) |
| `both`, `proto`, `fe`, `frontend`, `full` | Frontend-facing flag | **1 → 6 (all)** |
| *(empty / anything else)* | Undetermined | **Ask the user** which scope, then proceed |

The rest of the argument is the flag name / purpose. Example invocations:

- `/implement-feature-flag azuki-only enable_new_scoring_path` → backend-only, Steps 4–6
- `/implement-feature-flag both enable_previous_application_list_search_with_url_params` → full, Steps 1–6
- `/implement-feature-flag enable_x` → scope not given, **ask first**

**Never touch cred-proto for an `azuki-only` flag** — adding an unused proto field is
waste. If the argument is missing or ambiguous, ask before editing proto; do not
guess the scope.

## The two scopes

| Scope | Where the flag is read | Steps |
| --- | --- | --- |
| **Frontend-facing** | Frontend reads it from `GetFeatureFlags` RPC | 1 → 2 → 3 → 4 → 5 → 6 |
| **Backend-only** | Only azuki code (usecase / FSM / handler) reads it | **4 → 5b → 6** |

## Prerequisite ordering (important)

For a **frontend-facing** flag the two repos have a hard dependency:

```
cred-proto PR merged → release-and-publish workflow → publish-go.yml tags vX.Y.Z-go
                                                              │
                                                              ▼
                              azuki can `go get cred-proto@vX.Y.Z-go` (Step 3)
```

- The `vX.Y.Z-go` module tag azuki depends on **only exists after** the cred-proto PR
  is merged and the publish-go workflow runs. Step 3 (and the handler compiling in
  Step 5a) is **blocked** until then.
- You **can** prepare the azuki flag definition (Step 4) and handler wiring (Step 5a)
  in parallel on a branch, but that branch cannot build/merge until the proto release
  lands. Plan the two PRs accordingly: cred-proto first, azuki follows.

---

## Repos & Paths

- **cred-proto** (proto repo): `../cred-proto` (module `github.com/Finatext/cred-proto`)
  - SPC flags:      `proto/spc/rpc/get_feature_flags.proto`
  - Console flags:  `proto/console/rpc/get_feature_flags.proto`
  - Anmitsu flags:  `proto/anmitsu/rpc/get_feature_flags.proto`
  - Kintsuba flags: `proto/kintsuba/rpc/v1/get_feature_flags.proto`
- **azuki** (this repo):
  - Flag definitions: `internal/lib/feature/flag/*.go` (one file per domain)
  - Handlers: `internal/presentation/{spc_public,console_api,anmitsu_public,kintsuba_public}_api_presentation/internal/get_feature_flags/handler.go`

Pick the presentation that matches the consuming frontend (SPC borrower app → `spc`,
operator console → `console`, etc.).

---

## Step 1 — Add the field to the proto (frontend-facing only)

Edit the matching `get_feature_flags.proto`. Add a `bool` field to
`GetFeatureFlagsResponse` with a **doc comment** and the **next unused field number**.

```proto
// EnablePreviousApplicationListSearchWithUrlParams enables searching previous
// application list with URL parameters.
bool enable_previous_application_list_search_with_url_params = 128;
```

Rules:
- **Comment style**: start with the PascalCase name (e.g. `EnablePreviousApplicationListSearchWithUrlParams`), then a one-line description. Match the existing comments in the file.
- **Field number**: use a fresh number. Never reuse a `reserved` number, and never renumber or move existing fields.
- **Field name**: `snake_case` mirroring the Go/PascalCase name.
- Optionally add the JIRA ticket URL in a second comment line, as done for recent fields.

### Regenerate generated code

From the `cred-proto` repo root:

```bash
make gen   # or: make fmt && make gen
```

This runs `buf format` + code generation (Go/TS/OpenAPI) via Docker. Verify the new
field appears in the generated Go under `dist/go/spc/rpc/...` as
`EnablePreviousApplicationListSearchWithUrlParams`.

> Note: proto field `enable_mvp_credit_card` generates Go field `EnableMvpCreditCard`
> (protobuf initialisms). Check the generated name before referencing it in the handler.

---

## Step 2 — Open the cred-proto PR

Adding a **new field** to a message is a **backward-compatible** change.

- **Semver label: `release:minor`** (per team policy: use `release:minor` for
  everything except emergency fixes). Adding a field is never `release:major`
  (that's for moving/renaming/deleting) and not `release:patch` (that's
  comment-only / non-effective changes).
- **PR title** must include the JIRA ticket number (`CRES-XXXX`) — required for the
  STG release-note generation.
- Fill in `概要` (summary — what & why, with ticket/issue/Slack link) and `参考リンク`
  per `.github/pull_request_template.md`.

Draft PR body (Japanese, matching repo convention):

```markdown
## 概要

`GetFeatureFlagsResponse` に `enable_previous_application_list_search_with_url_params`
フィールドを追加します。<!-- なぜ必要か + チケットリンク -->

## 参考リンク

- https://finatexthd.atlassian.net/browse/CRES-XXXX
```

Create with `gh` (do not push/create without the user's go-ahead):

```bash
gh pr create --repo Finatext/cred-proto \
  --title "CRES-XXXX: add enable_previous_application_list_search_with_url_params to GetFeatureFlagsResponse" \
  --body-file <body>
```

After merge, cred-proto is released as a new tag (e.g. `vX.Y.Z`). You need that tag
for Step 3.

---

## Step 3 — Bump the proto dependency in azuki (frontend-facing only)

**Blocked until Step 2 is merged and published.** After the cred-proto PR merges, the
`release-and-publish` → `publish-go.yml` workflow produces the Go module tag
`vX.Y.Z-go` (note the `-go` suffix — that is the module version azuki consumes, not
the plain `vX.Y.Z` release tag). Only then:

```bash
go get github.com/Finatext/cred-proto@vX.Y.Z-go
go mod tidy
```

Confirm `go.mod` shows the new `github.com/Finatext/cred-proto vX.Y.Z-go`. Until this
is done the generated `EnablePreviousApplicationListSearchWithUrlParams` field will
not exist in azuki and the handler won't compile.

> Advanced (local pre-merge testing only): to develop azuki against the unreleased
> proto, run `make gen` in the local cred-proto checkout and add a temporary
> `replace github.com/Finatext/cred-proto => ../cred-proto` to `go.mod`. **Remove the
> replace and pin the real `-go` tag before opening/merging the azuki PR** — never
> merge a `replace` to a local path.

---

## Step 4 — Define the flag in azuki (ALWAYS)

Add the flag to the domain-appropriate file under `internal/lib/feature/flag/`
(e.g. SPC flags → `spc.go`). Use `feature.RegisterFlagSchema[bool]` with the full
option set:

```go
// EnablePreviousApplicationListSearchWithUrlParams enables searching previous
// application list with URL parameters.
var EnablePreviousApplicationListSearchWithUrlParams = feature.RegisterFlagSchema[bool](
	"enable_previous_application_list_search_with_url_params",
	feature.WithDescription("Enables searching the previous application list with URL parameters."),
	feature.WithMaintainedBy("<your-name>"),
	feature.WithTicketURL("https://finatexthd.atlassian.net/browse/CRES-XXXX"),
	feature.WithAddedOn(value.NewDate(2026, 7, 15)),
	feature.WithSunsetOn(value.NewDate(2026, 8, 5)), // ~three weeks after being defined
	feature.WithDefault(false),
	feature.WithDefault(true).ForEnv(value.EnvLocal, value.EnvTest, value.EnvDevelopment).ForLicensee(value.LicenseeIDSPC),
)
```

Conventions (see `use-feature-flag` for the full rationale):
- Variable name: `PascalCase`; schema key: `snake_case` (must match the proto field
  name for frontend-facing flags so the mapping is obvious).
- `Enable*` / `Disable*` prefix.
- Every flag needs a **sunset date** — flags are temporary and meant to be deleted.
- `WithDefault(false)` is the base; layer `WithDefault(true).ForEnv(...).ForLicensee(...)`
  for the rollout. Only use `LicenseeID` constants from
  `internal/lib/value/org_id.go`. **Never use `LicenseeIDManju`.**

For a **backend-only** flag, this step + Step 5 is all you need. Stop here.

---

## Step 5 — Wire it up

### 5a. Frontend-facing: return it from the handler

In the matching `get_feature_flags/handler.go`, read the flag with the existing
`query` and add it to the response. Follow the exact surrounding pattern — on error,
**log and treat as disabled** (do not return the error):

```go
enablePreviousApplicationListSearchWithUrlParams, err := feature.Flag(ctx, flag.EnablePreviousApplicationListSearchWithUrlParams, query)
if err != nil {
	log.Error("get enable_previous_application_list_search_with_url_params feature flag failed", logger.ErrorAttr(err))
}
```

```go
return connect.NewResponse(
	&rpc.GetFeatureFlagsResponse{
		// ...existing fields...
		EnablePreviousApplicationListSearchWithUrlParams: enablePreviousApplicationListSearchWithUrlParams,
	},
), nil
```

### 5b. Backend-only: branch on it where the behavior lives

Read it in the usecase / handler that owns the behavior, using the query type that
matches the scope, and write **delete-friendly** code (early-return the legacy path):

```go
enabled, err := feature.Flag(ctx, flag.EnablePreviousApplicationListSearchWithUrlParams, feature.LicenseeQuery(licenseeID))
if err != nil {
	logger.FromContext(ctx).Error("failed to get ... feature flag", logger.ErrorAttr(err))
}
if !enabled {
	return legacySearch(ctx, input) // old behavior, deleted when the flag is removed
}
return search(ctx, input) // canonical new behavior
```

---

## Step 6 — Lint, format, verify

Per the project rules, lint & format the packages you touched before committing:

```bash
./custom-gcl run --fix --timeout 30m --config ./.golangci.yml \
  ./internal/lib/feature/flag/... \
  ./internal/presentation/spc_public_api_presentation/...
go build ./...
```

Limit tests/lint to the changed and related files to keep it fast.

---

## Checklist

**Frontend-facing flag**
- [ ] Proto field added with doc comment + fresh field number (Step 1)
- [ ] `make gen` run in cred-proto; generated Go name confirmed
- [ ] cred-proto PR opened with `release:minor` + `CRES-XXXX` in title (Step 2)
- [ ] azuki `go.mod` bumped to the released `-go` tag after merge (Step 3)
- [ ] Flag defined in `internal/lib/feature/flag/*.go` with sunset date (Step 4)
- [ ] Handler returns the value, log-on-error pattern (Step 5a)
- [ ] Lint/format/build pass (Step 6)

**Backend-only flag**
- [ ] Flag defined in `internal/lib/feature/flag/*.go` with sunset date (Step 4)
- [ ] `feature.Flag()` branch written delete-friendly where behavior lives (Step 5b)
- [ ] No cred-proto / handler changes made
- [ ] Lint/format/build pass (Step 6)
