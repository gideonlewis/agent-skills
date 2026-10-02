---
name: spcc-app-feature-flag-cleanup
description: Xoá một feature flag đã rollout xong khỏi repo azuki-app (frontend Console) — gồm guard WithBooleanFeatureFlagGuard, chỗ đọc useSuspenseFeatureFlags, conditional spread trong menu.ts, route guard trong router.tsx, component legacy chỉ chạy khi flag tắt, và test mock. Dùng khi cần gỡ flag phía FE — việc này phải làm TRƯỚC và deploy trước, vì đây là Phase 1 của quy trình xoá 2 pha; flag backend bên azuki và field bên cred-proto được xoá sau ở Phase 2. Không dùng để xoá flag phía backend (dùng skill cleanup-feature-flag trong repo azuki), cũng không dùng để thêm flag mới (xem spcc-feature-flag-implementation).
argument-hint: "フィーチャーフラグ名 (例: enable_some_feature または enableSomeFeature)"
---

# フィーチャーフラグクリーンアップコマンド (azuki-app)

完全にロールアウトされたフィーチャーフラグの参照を、azuki-app (Console フロントエンド) から安全に削除するためのコマンドです。

## 目的

フィーチャーフラグは一時的なリリース制御メカニズムであり、ロールアウト完了後は削除する必要があります。このコマンドは、フラグ有効状態のコードパスのみを残し、フラグ無効時にのみ使われていたレガシー UI を除去します。

## 使用タイミング

- フィーチャーフラグがすべての環境とライセンシーで有効化され、安定している
- バックエンド (azuki) のフラグ削除に先立ち、フロントエンド参照を先に消す必要がある
- 古いフィーチャーフラグから技術的負債をクリーンアップしたい場合

## 重要: 2段階削除におけるこの Skill の位置

フラグ削除は必ず次の順序で行います。**このSkillはPhase 1です。**

```text
Phase 1 (このSkill)  azuki-app からフラグ参照を削除 → マージ → 本番デプロイ
                     ↓ 十分な時間を空ける (古いクライアントが残っていないことを確認)
Phase 2              azuki のバックエンドフラグと cred-proto のフィールドを削除
                     (azuki 側の .claude/skills/cleanup-feature-flag/SKILL.md を使用)
```

**順序を逆にしてはいけません。** フロントエンド参照が残ったままバックエンドのフラグを削除すると、`GetFeatureFlags` が `false` を返し、フロントエンドは無効化されたコードパスに戻るため機能が壊れます。

### このSkillで触らないもの

- `node_modules/@Finatext/cred-proto-ts-client-azuki-app/**` の生成型 (`get_feature_flags_pb`)
  - フラグのフィールド定義は cred-proto 側の管轄。azuki-app は参照をやめるだけで、フィールド自体は Phase 2 まで残る
- azuki (バックエンド) のコード
- 削除したフラグ名の再利用
  - 一度削除した名前は恒久欠番。azuki 側の CI `Validate Feature Flag Names` が git 履歴上の名前の再登録をブロックする

## 入力

- フィーチャーフラグ名
  - snake_case (`enable_some_feature`) — スプレッドシートやバックエンドでの表記
  - camelCase (`enableSomeFeature`) — proto 生成型でのフィールド名。azuki-app のコードはこちらを使う

## 実行手順

### 1. フラグ名の正規化と存在確認

バックエンドの snake_case 名は、proto 生成時に camelCase に変換されます。

```text
enable_console_engagement_history_view  →  enableConsoleEngagementHistoryView
enable_export_receivable_transfers      →  enableExportReceivableTransfers
```

生成型に存在することを確認します。

```bash
rg -n "enableSomeFeature" node_modules/@Finatext/cred-proto-ts-client-azuki-app/dist/esm/console/rpc/get_feature_flags_pb.d.ts
```

ヒットしない場合は、フラグ名の変換ミスか、ローカルの cred-proto が古い可能性があります。先に確認してから進めます。

### 2. 作業ツリーと参照箇所を調べる

```bash
git status --short

# camelCase 名で全参照を検索 (guard の featureFlagKey 文字列もこれで拾える)
rg -n "enableSomeFeature" src

# snake_case 名がコメントやテストに残っていないか
rg -n "enable_some_feature" src
```

参照を次に分類します。

- `WithBooleanFeatureFlagGuard` の `featureFlagKey` — ルートガード / 部分ガード
- `useSuspenseFeatureFlags()` の戻り値からの読み出し — 分割代入 または プロパティアクセス
- `src/models/menu.ts` の条件付きスプレッド — メニュー項目の出し分け
- テストのモック — `vi.mock('@/hooks/useFeatureFlags')`

### 3. パターン別に削除する (有効パスを残す)

#### パターン1: ルートガード (`src/plugins/router.tsx`)

`WithBooleanFeatureFlagGuard` を外し、children をそのまま残します。

```tsx
// 変更前
{
  path: 'contract/repayment-history',
  element: (
    <WithBooleanFeatureFlagGuard
      featureFlagKey="enableConsoleDisplayAndFilterTransactionList"
      fallback={<ErrorPage />}
    >
      <RepaymentHistory />
    </WithBooleanFeatureFlagGuard>
  ),
},

// 変更後
{
  path: 'contract/repayment-history',
  element: <RepaymentHistory />,
},
```

`RequiredPermissionPage` など他のラッパーが内側にある場合は、それらは残します。ガードだけを剥がします。

#### パターン2: コンポーネント内のガード

```tsx
// 変更前
<WithBooleanFeatureFlagGuard featureFlagKey="enableSomeFeature" fallback={null}>
  <ExportButton />
</WithBooleanFeatureFlagGuard>

// 変更後
<ExportButton />
```

#### パターン3: フック経由の読み出し + ローカル定数

```tsx
// 変更前
const featureFlags = useSuspenseFeatureFlags()
const enableExpandedEngagementFilter =
  featureFlags.enableExpandedEngagementFilter === true
...
{enableExpandedEngagementFilter && <ExpandedFilterFields />}

// 変更後 (定数ごと削除し、常に表示)
<ExpandedFilterFields />
```

同じファイルで他のフラグも読んでいる場合は `useSuspenseFeatureFlags()` の呼び出し自体は残します。対象フラグの定数と分岐だけを消します。

#### パターン4: 分割代入 + 条件式の一部

```tsx
// 変更前
const { enableAnnouncementReviewWorkflow } = useSuspenseFeatureFlags()
...
{canEdit &&
  (announcement.status === AnnouncementStatus.DRAFT ||
    announcement.status === AnnouncementStatus.PUBLISHED ||
    (enableAnnouncementReviewWorkflow === true &&
      announcement.status === AnnouncementStatus.REVIEW_REJECTED)) && (

// 変更後 (フラグ条件を取り除き、機能条件のみ残す)
{canEdit &&
  (announcement.status === AnnouncementStatus.DRAFT ||
    announcement.status === AnnouncementStatus.PUBLISHED ||
    announcement.status === AnnouncementStatus.REVIEW_REJECTED) && (
```

このファイルで他にフラグを読んでいなければ、`useSuspenseFeatureFlags` の行と import も削除します。

#### パターン5: メニューの条件付きスプレッド (`src/models/menu.ts`)

```ts
// 変更前
...(featureFlags?.enableConsoleEngagementHistoryView
  ? [
      {
        title: 'home.engagementHistory.title',
        url: '/borrower/engagement-history',
        hasArrow: true,
        option: {
          hiddenByLicensee: ['karukan' as const],
        },
      },
    ]
  : []),

// 変更後 (スプレッドをやめ、通常の要素として展開)
{
  title: 'home.engagementHistory.title',
  url: '/borrower/engagement-history',
  hasArrow: true,
  option: {
    hiddenByLicensee: ['karukan' as const],
  },
},
```

`as const` は配列リテラル内で必要だった型注釈です。展開後もそのまま残して問題ありません。外したことで型推論が変わる場合は `pnpm tsc` で検出されます。

#### パターン6: テストモック

```ts
// 変更前
vi.mock('@/hooks/useFeatureFlags', () => ({
  useSuspenseFeatureFlags: vi.fn(),
}))
mockUseSuspenseFeatureFlags.mockReturnValue({
  enableSomeFeature: true,
} as FeatureFlags)

// 変更後
// 対象フラグの指定を削除。他のフラグを使っていなければ vi.mock ごと削除する
```

フラグ ON/OFF の両方をテストしているケースがあれば、OFF 側のテストケースを削除し、ON 側だけを残します。

### 4. レガシーコードの削除

フラグ無効時にのみ使われていたコンポーネント・フック・ユーティリティを削除します。実績として、`enable_information` 系のクリーンアップでは `LegacyForm` コンポーネントを含む約 390 行が削除されています (`git show de7550e6`)。

```bash
# 参照が 0 になったコンポーネントを確認してから削除
rg -n "LegacyForm" src
```

削除対象の典型例:

- `LegacyXxx` / `OldXxx` といった命名のコンポーネント
- 旧実装専用の hook、型、定数
- 旧実装でのみ使われていた i18n キー (`src/locales/**`)

### 5. 残存物を掃除する

```bash
# 未使用になった import を検出
pnpm lint:eslint
```

確認するもの:

- `WithBooleanFeatureFlagGuard` の import — ファイル内で他に使っていなければ削除
- `useSuspenseFeatureFlags` の import と呼び出し — 他のフラグを読んでいなければ削除
- ガードの `fallback` 専用に import していた `ErrorPage` など
- 旧実装専用だった props / 型定義

### 6. 検証

```bash
pnpm tsc          # 型チェック (proto フィールド参照漏れもここで出る)
pnpm lint         # eslint / prettier / stylelint
pnpm fix          # 自動修正が必要な場合
pnpm test:unit:ci # ユニットテスト
```

さらに、対象画面を実際に開いて確認します。

```bash
pnpm dev
```

確認ポイント:

- フラグで出し分けていた画面・メニュー・ボタンが、常に表示されること
- ルートガードを外したページに直接 URL でアクセスできること
- `hiddenByLicensee` などフラグ以外の出し分け条件が壊れていないこと

### 7. PR 作成とバックエンドへの連携

PR の説明に必ず含めるもの:

- 削除したフラグ名 (snake_case と camelCase の両方)
- Phase 1 (frontend) であること、Phase 2 (azuki + cred-proto) が別途必要であること
- 元のロールアウト PR / チケットへのリンク

マージ・本番デプロイ後、azuki 側のフラグ削除 (Phase 2) を依頼または実施します。

## 品質ゲート

- 対象フラグへの参照が azuki-app から完全に消えている (`rg` で 0 件)
- 「有効」コードパスのみが残っている
- 無効パスでのみ使われていたレガシーコンポーネントが削除されている
- 未使用の import / hook 呼び出しが残っていない
- `pnpm tsc` / `pnpm lint` / `pnpm test:unit:ci` が通る
- 対象画面を実際に開いて表示を確認した
- proto 生成型 (`get_feature_flags_pb`) には手を入れていない

## よくある落とし穴

1. **削除順序の誤り**: azuki-app の削除・デプロイが先。バックエンドを先に消すと機能が壊れる
2. **間違ったパスを選択する**: 常に「有効」パスを残し、「無効」パスは残さない
3. **デッドコードを残す**: フラグ無効時にのみ使われていたレガシーコンポーネントを消し忘れる
4. **`useSuspenseFeatureFlags()` の消し忘れ**: 分岐だけ消してフック呼び出しを残すと未使用変数として残る。逆に、同じファイルで他のフラグを読んでいるのに呼び出しごと消してしまうのも誤り
5. **menu.ts のスプレッド展開ミス**: `...(cond ? [{...}] : [])` を配列要素として正しく展開せず、配列の入れ子を作ってしまう
6. **テストの OFF ケースを残す**: フラグ無効時の挙動を検証するテストは、フラグと一緒に削除する
7. **camelCase 変換ミス**: `enable_feature_get_authentication_attempt` → `enableFeatureGetAuthenticationAttempt` のように、機械的に変換する。生成型で実在を確認してから作業する
8. **削除したフラグ名は再利用不可**: revert 後に再度入れる場合も新しい名前を付ける (例: `enable_foo_v2`)

## 関連ドキュメント

- `azuki/.claude/skills/cleanup-feature-flag/SKILL.md` — Phase 2 (バックエンド側) の手順
- `azuki/.github/instructions/release_procedure.instructions.md` — 2段階フラグ削除を含むリリース手順
- `.claude/skills/console-to-core-api-migration/SKILL.md` — `enable_console_api_to_core_api_migrate_chunk_*` フラグの撤去手順
- `src/hooks/useFeatureFlags.ts` — フラグ取得フック
- `src/components/WithBooleanFeatureFlagGuard.tsx` — Boolean フラグ用のガードコンポーネント
- 参考コミット: `de7550e6` (`chore: remove announcement related featureflags`)
