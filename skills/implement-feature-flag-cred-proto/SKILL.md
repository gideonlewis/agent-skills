---
name: implement-feature-flag-cred-proto
description: |
  Phase 1 of a frontend-facing feature flag: add a bool field to
  GetFeatureFlagsResponse in the cred-proto repo, regenerate code, and open the
  release PR. Use when a feature flag must be exposed to the frontend via the
  GetFeatureFlags RPC. After the PR is merged & published, continue with the
  implement-feature-flag-azuki skill. Backend-only flags skip this skill entirely.
argument-hint: "<flag name / purpose> [presentation: spc|console|anmitsu|kintsuba]"
---

# Implement a Feature Flag — Phase 1 (cred-proto)

This is the **proto side** of a frontend-facing feature flag. It ends at "PR opened".
The azuki side (flag definition + handler wiring) is a **separate skill**,
`implement-feature-flag-azuki`, run **after** this PR is merged and published.

## When to use / skip

- **Use** only when the frontend must read the flag from the `GetFeatureFlags` RPC.
- **Skip entirely** for a **backend-only** flag (only azuki code reads it). Go straight
  to `implement-feature-flag-azuki` — adding an unused proto field is waste.
- If unsure whether the frontend needs it, ask the user before editing proto.

## Prerequisite ordering (why this is Phase 1)

```
[THIS SKILL] cred-proto PR merged → release-and-publish → publish-go.yml tags vX.Y.Z-go
                                                                   │
                                                                   ▼
             [implement-feature-flag-azuki] go get cred-proto@vX.Y.Z-go
```

The `vX.Y.Z-go` module tag azuki depends on **only exists after** this PR is merged and
the `publish-go.yml` workflow runs. Do not start the azuki-side version bump until then.

## Repo & paths (cred-proto)

Module `github.com/Finatext/cred-proto`. Edit the file matching the consuming frontend:

- SPC (borrower app): `proto/spc/rpc/get_feature_flags.proto`
- Console (operator):  `proto/console/rpc/get_feature_flags.proto`
- Anmitsu:             `proto/anmitsu/rpc/get_feature_flags.proto`
- Kintsuba:            `proto/kintsuba/rpc/v1/get_feature_flags.proto`

---

## Step 1 — Add the field to the proto

Add a `bool` field to `GetFeatureFlagsResponse` with a **doc comment** and the
**next unused field number**.

```proto
// EnablePreviousApplicationListSearchWithUrlParams enables searching previous
// application list with URL parameters.
bool enable_previous_application_list_search_with_url_params = 128;
```

Rules:
- **Comment style**: start with the PascalCase name, then a one-line description. Match the existing comments in the file. Optionally add the JIRA URL on a second line.
- **Field number**: use a fresh number. Never reuse a `reserved` number; never renumber or move existing fields.
- **Field name**: `snake_case` mirroring the PascalCase name. Keep this identical to the azuki flag schema key so the mapping is obvious.

### Regenerate generated code

From the `cred-proto` repo root:

```bash
make gen   # or: make fmt && make gen
```

Runs `buf format` + code generation (Go/TS/OpenAPI) via Docker. Verify the new field
appears in the generated Go under `dist/go/<pres>/rpc/...`.

> Note: proto field `enable_mvp_credit_card` generates Go field `EnableMvpCreditCard`
> (protobuf initialisms). Note the generated Go name — the azuki skill needs it for
> the handler.

---

## Step 2 — Open the cred-proto PR

Adding a **new field** to a message is a **backward-compatible** change.

- **Semver label: `release:minor`** (team policy: `release:minor` for everything
  except emergency fixes). Not `release:major` (that's moving/renaming/deleting) and
  not `release:patch` (comment-only / non-effective changes).
- **PR title** must include the JIRA ticket number (`CRES-XXXX`) — required for STG
  release-note generation.
- Fill in `概要` (what & why, with ticket/issue/Slack link) and `参考リンク` per
  `.github/pull_request_template.md`.

Draft PR body (Japanese, matching repo convention):

```markdown
## 概要

`GetFeatureFlagsResponse` に `enable_previous_application_list_search_with_url_params`
フィールドを追加します。<!-- なぜ必要か + チケットリンク -->

## 参考リンク

- https://finatexthd.atlassian.net/browse/CRES-XXXX
```

Create with `gh` (confirm with the user before creating):

```bash
gh pr create --repo Finatext/cred-proto \
  --title "CRES-XXXX: add enable_previous_application_list_search_with_url_params to GetFeatureFlagsResponse" \
  --body-file <body>
```

**Do not merge automatically.** The PR is reviewed and **merged manually**. After merge,
`publish-go.yml` produces the `vX.Y.Z-go` module tag.

---

## Next

Once the PR is merged and the `-go` tag is published, note the released cred-proto
version (e.g. `v1.51.0`) and run:

```
/implement-feature-flag-azuki <same flag name> v1.51.0
```

to bump the proto dependency to that version, define the flag, and wire the handler.

## Checklist (Phase 1)

- [ ] Correct `get_feature_flags.proto` chosen for the consuming frontend
- [ ] `bool` field added with doc comment + fresh field number
- [ ] `make gen` run; generated Go field name noted for the azuki skill
- [ ] PR opened with `release:minor` label + `CRES-XXXX` in the title
- [ ] PR body follows the template (概要 / 参考リンク)
- [ ] Handoff: after manual merge + publish, continue with `implement-feature-flag-azuki`
