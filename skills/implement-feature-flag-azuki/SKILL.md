---
name: implement-feature-flag-azuki
description: |
  Implement a feature flag on the azuki side — define it under
  internal/lib/feature/flag and wire it into a get_feature_flags handler
  (frontend-facing) or a usecase branch (backend-only). For a frontend-facing flag,
  run this AFTER implement-feature-flag-cred-proto's PR is merged and the vX.Y.Z-go
  tag is published, passing that version. For a backend-only flag, run standalone
  (no proto, no version).
argument-hint: "<flag name / purpose> [cred-proto version, e.g. v1.51.0]"
---

# Implement a Feature Flag — azuki side

This is the **azuki side** of a feature flag. For general best practices (naming,
override precedence, delete-friendly code, tests) defer to the `use-feature-flag`
skill — this skill focuses on the concrete **wiring**.

## First: frontend-facing or backend-only?

**Decide from the user's request.** If the request says the flag is used **only in the
backend** (no frontend behavior depends on it), it is **backend-only** — do NOT
implement it in the `GetFeatureFlags` API and do NOT bump the proto version. Otherwise,
if the frontend must read it via `GetFeatureFlags`, it is **frontend-facing**.

| Case | Comes from | What to do |
| --- | --- | --- |
| **Frontend-facing** | Frontend reads it via `GetFeatureFlags`; Phase 1 (`implement-feature-flag-cred-proto`) was run; a cred-proto version is provided | Steps **1 → 2 → 3a → 4** |
| **Backend-only** | Request states the flag is backend-only | Steps **2 → 3b → 4** (skip proto bump & handler) |

Confirm the frontend-facing case if needed: the field should exist in the released
proto, e.g. `grep -r "<snake_case_name>" ../cred-proto/proto/*/rpc/get_feature_flags.proto`.
If the intent is unclear from the request, ask.

> **Never add a proto field from this skill.** Proto changes belong to
> `implement-feature-flag-cred-proto`. If a frontend-facing flag has no proto field
> yet, stop and run that skill first.

## azuki paths

- Flag definitions: `internal/lib/feature/flag/*.go` (one file per domain, e.g. `spc.go`)
- Handlers: `internal/presentation/{spc_public,console_api,anmitsu_public,kintsuba_public}_api_presentation/internal/get_feature_flags/handler.go`

---

## Step 1 — Bump the proto dependency (frontend-facing only)

**Requires Phase 1 merged & published.** Use the **cred-proto version passed as the
argument** (e.g. `v1.51.0`). The azuki module tag has a **`-go` suffix**, so normalize
it: `v1.51.0` → `v1.51.0-go` (if the argument already ends in `-go`, use it as-is).

```bash
# argument: v1.51.0  →  go get target: v1.51.0-go
go get github.com/Finatext/cred-proto@v1.51.0-go
go mod tidy
```

If no version was provided for a frontend-facing flag, **ask the user for it** (it is
the cred-proto release created after Phase 1 merged). Do not guess — bumping to the
wrong version means the generated field is missing and the handler (Step 3a) won't
compile. To look one up: `gh release list --repo Finatext/cred-proto`.

Confirm `go.mod` shows the new `github.com/Finatext/cred-proto vX.Y.Z-go`.

> Advanced (local pre-merge testing only): to develop against unreleased proto, run
> `make gen` in the local cred-proto checkout and add a temporary
> `replace github.com/Finatext/cred-proto => ../cred-proto` to `go.mod`. **Remove the
> replace and pin the real `-go` tag before opening/merging the azuki PR** — never
> merge a `replace` to a local path.

---

## Step 2 — Define the flag (ALWAYS)

Add the flag to the domain-appropriate file under `internal/lib/feature/flag/`
(e.g. SPC flags → `spc.go`) using `feature.RegisterFlagSchema[bool]`:

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

Conventions (see `use-feature-flag` for the rationale):
- Variable name `PascalCase`; schema key `snake_case`. For a frontend-facing flag the
  schema key **must match the proto field name**.
- `Enable*` / `Disable*` prefix.
- Every flag needs a **sunset date** — flags are temporary and meant to be deleted.
- `WithDefault(false)` base, then `WithDefault(true).ForEnv(...).ForLicensee(...)` for
  rollout. Only use `LicenseeID` constants from `internal/lib/value/org_id.go`.
  **Never use `LicenseeIDManju`.**

---

## Step 3 — Wire it up

### 3a. Frontend-facing: return it from the handler

In the matching `get_feature_flags/handler.go`, read the flag with the existing `query`
and add it to the response. Follow the surrounding pattern — on error, **log and treat
as disabled** (do not return the error):

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

> Use the **generated** Go field name from Phase 1 (e.g. `EnableMvpCreditCard` for
> `enable_mvp_credit_card`).

### 3b. Backend-only: branch where the behavior lives

Read it in the usecase / handler that owns the behavior, with the matching query type,
and write **delete-friendly** code (early-return the legacy path):

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

## Step 4 — Lint, format, build

Lint & format the packages you touched before committing:

```bash
./custom-gcl run --fix --timeout 30m --config ./.golangci.yml \
  ./internal/lib/feature/flag/... \
  ./internal/presentation/spc_public_api_presentation/...
go build ./...
```

Limit tests/lint to the changed and related files to keep it fast.

---

## Checklist

**Frontend-facing (Phase 2, after cred-proto merged)**
- [ ] `go.mod` bumped to the released `-go` tag (Step 1)
- [ ] Flag defined in `internal/lib/feature/flag/*.go`, schema key == proto field name, sunset date set (Step 2)
- [ ] Handler returns the value, log-on-error pattern, correct generated Go field name (Step 3a)
- [ ] Lint/format/build pass (Step 4)

**Backend-only (standalone)**
- [ ] Flag defined in `internal/lib/feature/flag/*.go` with sunset date (Step 2)
- [ ] `feature.Flag()` branch written delete-friendly where behavior lives (Step 3b)
- [ ] No proto / handler / go.mod-proto changes made
- [ ] Lint/format/build pass (Step 4)
