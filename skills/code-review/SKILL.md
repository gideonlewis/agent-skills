---
name: code-review
description: >
  Dùng skill này khi review MR/PR, diff, commit, hoặc code change trên AI
  Platform GitLab trong group ai-platform, đặc biệt khi một Mattermost thread
  yêu cầu code review, reviewer feedback, findings, rủi ro blocker/non-blocker,
  hoặc yêu cầu mention người implement và reviewer sau khi review.
version: 0.1.5
author: TEQ AI Platform
license: Internal
metadata:
  hermes:
    tags: [ai-platform, code-review, gitlab, mattermost, merge-requests]
---

# AI Platform Code Review

Skill này hướng dẫn AI Platform PM agent review code change trên GitLab theo
workflow của team R&D: đọc context từ Mattermost, lấy evidence từ GitLab,
đối chiếu design/guardrails khi cần, rồi trả findings rõ owner và next action.

## Khi Nào Dùng

Dùng skill này khi user cần:

- Review GitLab MR/PR, diff, commit hoặc code change trong group `ai-platform`.
- Đọc Mattermost thread để hiểu đang review MR nào, ai code, ai review, và focus
  review là gì.
- Tóm tắt blocker/non-blocker findings cho MR.
- Soát risk trước khi reviewer approve/merge.
- Draft review result có mention người implement và reviewer trong Mattermost.

Không dùng skill này cho:

- Chỉ kiểm tra trạng thái MR, pipeline, commit, release hoặc implementation
  evidence mà không cần code review. Dùng `ai-platform-gitlab`.
- Câu hỏi vision, architecture, decision, research, runbook. Dùng
  `knowledge-search`.
- Chỉ đọc hoặc cập nhật ticket Backlog mà không review code. Dùng `backlog`.
- Review code ngoài TEQ GitLab hoặc ngoài group `ai-platform`, trừ khi user
  explicit mở scope.

## Source Boundary

- GitLab host mặc định: `git.teqnological.asia`.
- Group mặc định: `ai-platform`.
- Nếu user đưa GitLab link, dùng đúng link đó trước. Không quét nhiều repo để
  đoán target.
- Kế thừa boundary từ `ai-platform-gitlab`: claim về MR/diff/pipeline phải dựa
  trên live evidence hoặc direct link; không nói "đã deploy" chỉ vì MR merged.
- Kế thừa boundary từ `backlog`: MR phải link `TRT-<number>` trong description,
  và nội dung ticket Backlog là execution context chính cho review.
- Với design rationale, ADR, R&D guideline hoặc Agora docs, dùng
  `knowledge-search` để đọc source gốc thay vì suy luận từ MR.

## Mattermost Thread Context

Khi request đến từ Mattermost thread hoặc user đưa Mattermost permalink:

1. Đọc root post và replies trong thread bằng Mattermost read/thread tool đang
   được runtime expose. Nếu runtime không expose thread context, hỏi user đưa
   permalink hoặc paste thread.
2. Trích xuất các field sau:
   - MR/PR URL, repo path, hoặc commit/diff cần review.
   - Người implement/code change.
   - Reviewer hoặc người được yêu cầu review.
   - Review focus, deadline, constraint, linked ticket hoặc design doc.
3. Nếu thread và GitLab metadata mâu thuẫn:
   - Dùng GitLab live data cho trạng thái MR, author, branch, pipeline.
   - Dùng thread cho human intent như reviewer focus hoặc người cần được
     mention.
   - Ghi rõ conflict hoặc inference trong output.
4. Nếu không tìm được MR/PR target sau khi đọc thread, hỏi lại ngắn gọn. Không
   tự search toàn group để đoán.

### Mention Rule

- Khi trả lời trực tiếp trong Mattermost thread, mở đầu final response bằng role
  labels: `**Reviewer:** @reviewer | **Implementer:** @implementer` nếu đã xác định
  được Mattermost handles.
- `@ai-platform-pm` hoặc bot/agent handle được mention
  để gọi review chỉ là request target, không phải human reviewer. Không tự điền
  bot handle vào role `Reviewer` hoặc `Implementer`.
- Reviewer là human reviewer/requested reviewer trong thread, reviewer trong
  GitLab MR metadata, hoặc human requester đã trigger agent review. Ưu tiên
  GitLab MR reviewer/requested reviewer nếu có; nếu không có, dùng người trigger
  review trong Mattermost thread. Nếu chỉ thấy bot được mention và không xác
  định được human requester/reviewer, ghi `**Reviewer:** chưa xác định`.
- Nếu dùng human requester làm reviewer fallback, annotate ngay trên role line,
  ví dụ `**Reviewer:** @user (inferred từ root post author; MR chưa có reviewer)`.
- Reuse exact `@username` xuất hiện trong thread. Nếu chỉ có GitLab username
  hoặc display name, không tự bịa Mattermost handle; nêu tên không có `@` và
  ghi thiếu handle nếu mention là bắt buộc.
- Nếu không xác định được implementer, ghi `**Implementer:** chưa xác định` thay vì
  đoán từ người gọi bot.
- Nếu một người vừa implement vừa review, vẫn ghi rõ cả hai role:
  `**Reviewer:** @user | **Implementer:** @user`.
- Nếu dùng Mattermost write tool để post/reply ngoài cơ chế final response mặc
  định của gateway, phải xin user confirm rõ target thread/channel và preview
  message trước khi gọi tool write.

## Review Workflow

### Step 1: Xác Định Target Và Roles

- Lấy MR/PR target từ user message, Mattermost thread, hoặc GitLab link.
- Xác định implementer, reviewer, requested reviewer focus và deadline nếu có.
- Nếu MR link thiếu nhưng thread có repo + IID rõ ràng, dùng repo + IID đó.
- Nếu có nhiều MR candidates hoặc thiếu target chính, hỏi lại thay vì đoán.

### Step 2: Thu Thập GitLab Evidence

Ưu tiên GitLab MCP tool nếu runtime expose. Nếu phải fallback CLI, dùng host
explicit:

```bash
glab api --hostname git.teqnological.asia ...
```

Thu thập tối thiểu:

- MR metadata: title, repo, source/target branch, author, assignees, reviewers,
  state, draft/mergeability, web URL, description.
- Diff context đủ để review behavior chính; chỉ dùng changed files để định vị
  diff, không dùng làm nội dung tóm tắt mặc định.
- MR discussions/comments nếu user hỏi review tiếp một MR đang có feedback.
- Linked issue/ticket/design doc nếu nằm trong MR description hoặc thread.

Thu thập pipeline/check status chỉ khi:

- User hoặc thread explicit yêu cầu xem CI, code quality, test job hoặc pipeline.
- MR metadata trả về failed/blocked required check ngay trong dữ liệu đang đọc.
- Finding phụ thuộc trực tiếp vào test/eval/check evidence.

Không coi thiếu pipeline là issue mặc định. Không yêu cầu chạy CI/local test chỉ
vì MR không có pipeline evidence, trừ khi user hỏi assurance/test status hoặc
review phát hiện risk cần regression evidence.

Khi xử lý diff, giữ output theo constraint sau: không liệt kê toàn bộ changed
files trong câu trả lời mặc định. Không thêm dòng `Diff chính`,
`Changed files`, hoặc danh sách path trong phần `Evidence`/`REF`. Chỉ nêu file
hoặc path inline trong từng finding khi đó là evidence trực tiếp, ví dụ file
chứa bug, schema, migration, auth boundary hoặc test liên quan.

Khi cần mô tả phạm vi diff, gom theo behavior/component:

- `Offwork heatmap payload schema`
- `MCP tool registry wrapper`
- `Tests for validation and payload conversion`

Chỉ thêm danh sách file khi user yêu cầu rõ. Nếu cần nói phạm vi thay đổi, dùng
component/behavior summary thay vì path list.

### Step 3: Đọc TRT Ticket Context

Mọi MR trong group `ai-platform` phải có mã Backlog `TRT-<number>` trong MR
description. Khi review MR:

1. Extract tất cả mã `TRT-\d+` từ MR description.
2. Nếu không có mã `TRT`, tạo finding `Recommendation` category `Traceability`
   yêu cầu thêm ticket vào MR description. Không tự đoán ticket từ branch name,
   title, commit message hoặc Mattermost thread.
3. Nếu có nhiều mã `TRT`, đọc từng ticket có liên quan trực tiếp hoặc ghi rõ mã
   nào là primary context nếu MR description phân biệt.
4. Dùng skill/tool Backlog để fetch nội dung ticket: summary, description,
   done conditions, assignee, status, linked output/evidence nếu có.
5. Diễn giải status theo lifecycle TRT trước khi kết luận về evidence:
   - `Resolved` nghĩa là developer đã done phần implementation và handoff
     MR/output để review, không phải ticket đã hoàn tất end-to-end. Đánh giá
     merge readiness và các Done Conditions xác minh được trước merge; Done
     Conditions chỉ kiểm được sau merge, như deploy dev hoặc smoke test, có thể
     còn chưa tick và không là thiếu evidence mặc định.
   - `Closed` nghĩa là mọi Done Conditions đã được xác minh và ticket creator đã
     close ticket sau khi xem xét review result. Reviewer không mặc định là
     ticket creator và không tự quyết định close. Với feature, bug, hoặc thay
     đổi runtime, closure cần verification trên dev khi ticket hoặc release
     flow yêu cầu rõ; production không là gate cho ticket gốc. Nếu user yêu cầu
     audit ticket `Closed`, đánh giá closure readiness và evidence end-to-end
     theo ticket.
   - Với ticket `Open` hoặc `In Progress`, không suy diễn ticket đã hoàn tất từ
     MR hoặc pipeline; chỉ nêu trạng thái thực tế và action còn lại.
6. Đối chiếu MR với ticket: mục tiêu, scope, done conditions, expected behavior,
   non-goals và owner. Nếu MR làm lệch ticket hoặc thiếu done condition quan
   trọng **trước merge**, review theo severity dựa trên impact. Điều kiện chỉ
   thực hiện sau merge phải được nêu là remaining condition before `Closed`,
   không tự biến thành finding code review.

Thiếu mã `TRT` trong MR description là vấn đề traceability. Mặc định để
`Recommendation`, nâng lên `Blocker` chỉ khi team/user explicit yêu cầu policy
MR không được merge khi thiếu ticket, hoặc MR thay đổi public/production
contract mà không có execution tracker để xác nhận scope.

Nếu MR có mã `TRT` nhưng Backlog runtime không đọc được ticket, ghi một dòng
`Missing evidence` ngắn và không suy luận ticket từ branch/title.

### Step 4: Đọc Design Context Khi Cần

Design docs dài hạn nằm trong repo `ai-platform/ai-platform-agora`, chủ yếu ở:

- `docs/design-docs/` cho architecture/system design.
- `docs/decisions/` cho ADR/decision.
- `docs/vision/` cho vision định hướng dài hạn.

Đọc Agora/design docs qua `knowledge-search` khi MR chạm vào:

- Agent/platform workflow, skill, evaluation hoặc prompt behavior.
- MCP server/tool contract, tool naming, schema, gateway routing.
- RBAC, auth, OAuth, token, secret, policy, audit hoặc observability.
- Data model, migration, rollout, backward compatibility.
- Quyết định architecture có khả năng cần ADR hoặc update design doc.

Khi MR có khả năng ảnh hưởng thiết kế hệ thống:

1. Tìm design REF trong MR description, linked TRT ticket, Mattermost thread,
   hoặc MR discussion. Design REF có thể là link Agora doc, path dưới
   `docs/design-docs/`, ADR, hoặc explicit note "the design is in ...".
2. Nếu có REF, đọc source gốc bằng `knowledge-search` trước khi review design
   alignment. Không kết luận từ snippet hoặc ticket summary.
3. Nếu không có REF, phán đoán theo scope:
   - Nếu change chỉ là implementation cục bộ, bugfix nhỏ, wording, test, hoặc
     internal refactor không đổi contract: không cần tạo finding thiếu docs.
   - Nếu change đổi public/tool/API contract, auth/RBAC/security boundary,
     data model, migration/rollout behavior, gateway routing, hoặc agent
     workflow contract: tạo `Recommendation` category `Design` hỏi bổ sung
     design REF hoặc cập nhật Agora docs.
   - Nếu change làm trái documented design/ADR đã đọc, hoặc thay đổi
     public/production contract lớn mà không có design source để xác nhận scope,
     cân nhắc `Blocker` theo impact.
4. Khi user/thread nói "đã design trước", kiểm tra REF tới Agora/design source.
   Nếu chỉ nói miệng mà không có link/doc, ghi là missing design evidence thay
   vì coi là đã có design.

Không block MR chỉ vì thiếu docs. Chỉ nêu blocker khi code làm sai contract đã
có, thay đổi public boundary nhưng không có migration/compatibility, hoặc docs
là source of truth bắt buộc cho decision đó.

### Step 5: Review Checklist

Đánh giá các nhóm sau, tập trung vào risk thật và evidence:

- Với MR liên quan MCP tool, ưu tiên `Security`, `MCP/tool contract`, và
  `Backward compatibility`.
- Với MR liên quan gateway/RBAC/auth, ưu tiên `Security`, `Gateway/RBAC
  boundary`, và `Observability`.
- Với MR liên quan skill/prompt/docs, ưu tiên `Correctness`, `Design
  alignment`, và `Test/Eval coverage` nếu behavior cần fixture/eval.
- Với mọi MR, luôn kiểm tra `Traceability`: MR description có mã `TRT` và nội
  dung MR khớp ticket Backlog.
- Với MR ảnh hưởng system design, kiểm tra `Design`: có REF tới Agora design
  doc/ADR khi cần, hoặc có lý do rõ vì sao không cần design doc.
- Các nhóm còn lại là scan để phát hiện risk, không phải checklist bắt buộc
  phải sinh finding.

- Traceability: MR description có mã `TRT`, ticket đọc được, scope/done
  conditions khớp thay đổi.
- Design: design REF trong MR/thread/ticket khi thay đổi ảnh hưởng architecture,
  contract, migration, RBAC/auth, gateway routing hoặc agent workflow.
- Correctness: logic đúng với requirement, edge cases, error handling.
- Security: secret/config leak, injection, auth bypass, over-permission,
  unsafe logging, sensitive data exposure.
- Test/Eval coverage: unit/integration/eval, fixture, regression case, failed
  required check nếu có, missing validation cho behavior quan trọng.
- Backward compatibility: API/schema/config/env var, migration, rollout,
  rollback, consumers cũ.
- MCP/tool contract: naming, parameter schema, side effect description,
  result/error actionable, namespace/gateway compatibility.
- Gateway/RBAC boundary: identity propagation, policy enforcement, audit trail,
  rate/budget limit, token handling.
- Observability: logs, metrics, trace IDs, actionable error messages.
- Design alignment: khớp Agora current truth, ADR, documented trade-off.
- Operational risk: deploy order, feature flag, manual step, data recovery.

## Severity

- `Blocker`: chỉ dùng khi evidence cho thấy một trong các điều sau cần sửa
  trước merge:
  - Secret/sensitive data exposure, auth bypass, hoặc policy bypass.
  - Primary workflow hoặc public contract bị break với current/known consumer.
  - Data loss/corruption hoặc state change khó rollback.
  - Migration/backward compatibility risk không có fallback cho consumer hiện có.
  - Required check/eval failed trên behavior bị MR thay đổi.
  - Vi phạm documented contract/ADR bắt buộc của AI Platform.
  - MR thay đổi public/production contract nhưng không có `TRT` context để xác
    nhận scope hoặc owner, nếu policy/team yêu cầu ticket trước merge.
  - MR thay đổi public/production design boundary lớn nhưng không có design REF
    hoặc migration/compatibility rationale để reviewer xác nhận scope.
- `Recommendation`: cải thiện đáng làm nhưng không nên chặn merge nếu risk đã
  được hiểu và reviewer đồng ý. Nếu impact còn là inference hoặc chưa có
  evidence trực tiếp, mặc định để ở mức này, không nâng lên `Blocker`.
- `Nit`: wording/style nhỏ. Chỉ nêu khi user yêu cầu review kỹ hoặc nit ảnh
  hưởng readability đáng kể.

Mỗi finding phải có: `**Location/Evidence:**`, `**Impact:**`, `**Next action:**`,
owner đề xuất.
Nếu thiếu evidence đủ rõ, ghi một dòng `Missing evidence` ngắn hoặc hỏi lại.

Với mỗi finding, thêm category tag ngay sau ID và bold toàn bộ tag, ví dụ
`**[B1][Security]**`, `**[R1][Contract]**`, `**[R2][Test/Eval]**`. Category
nên là một nhóm trong checklist hoặc domain ngắn reviewer dễ scan. Dùng
`Location/Evidence` thay vì chỉ `Evidence`: ưu tiên `file:line` hoặc hunk khi
có, nhưng không bắt buộc. Với finding kiểu contract/design, `Location/Evidence`
có thể là schema block, MR description, design doc, ADR, discussion link hoặc
tool contract liên quan.

Không hiển thị confidence score trong Mattermost output. Chỉ report finding khi
evidence đủ rõ để reviewer hành động; nếu chưa đủ rõ, ghi tối đa một dòng
`Missing evidence` hoặc hỏi lại. Không thêm XML/JSON structured block trong
Mattermost output cho tới khi có automation consumer thật.

## Output Format

Khi trả lời trong Mattermost thread:

```markdown
**Reviewer:** @reviewer | **Implementer:** @implementer
**Kết luận:** <approve with notes / cần sửa trước khi merge / chưa đủ evidence>.
**Ticket action:** <khi có TRT: giữ Resolved để review hoặc khi Done Conditions hậu merge/dev còn mở; Resolved -> In Progress nếu cần sửa; hoặc ticket creator đóng trực tiếp Resolved -> Closed khi mọi Done Conditions đã đạt>.

**Blockers**
- **[B1][Category]** <finding>. **Location/Evidence:** <file:line | hunk | schema | link>.
  **Impact:** <risk>. **Next action:** @owner <action>.

**Recommendations**
- **[R1][Category]** <finding>. **Location/Evidence:** <file:line | hunk | schema | link>.
  **Impact:** <risk>. **Next action:** @owner <action>.

**REF:** MR <link> | Backlog <TRT link hoặc "missing"> | Design <doc/ADR hoặc "missing"> nếu liên quan
**Missing evidence:** <chỉ ghi nếu ảnh hưởng kết luận; tối đa 1 dòng, 2 ý ngắn>
```

Bold các label/header trong output như `**Reviewer:**`, `**Implementer:**`,
`**Kết luận:**`, `**Blockers**`, `**Recommendations**`, `**REF:**`,
`**Location/Evidence:**`, `**Impact:**`, `**Next action:**`,
`**Missing evidence:**`, `**Checks:**`, `**Findings:**`, và `**Ticket action:**`. Chỉ bold label
hoặc heading, không bold toàn bộ nội dung phía sau.

Khi Backlog ticket đọc được, luôn nêu `**Ticket action:**` ngay sau kết luận:

- Ticket đang `Open` hoặc `In Progress`: nêu status hiện tại, owner của next
  action và điều kiện còn lại để developer handoff. Không đề xuất transition;
  quyết định `In Progress -> Resolved` thuộc implementer, không phải kết luận
  của reviewer.
- Ticket đang `Resolved`:
  - Có finding cần implementer sửa: đề xuất `Resolved -> In Progress`, nêu
    owner là implementer và feedback cần xử lý.
  - MR có thể approve/merge nhưng còn Done Conditions sau merge/dev: giữ
    `Resolved`; nêu điều kiện cụ thể trước `Closed`.
  - Evidence cho thấy mọi Done Conditions áp dụng đã đạt: nêu reviewer có thể
    bàn giao review result để ticket creator đóng trực tiếp `Resolved -> Closed`;
    không đòi approval artifact riêng.

Đây là đề xuất workflow trong review output; không tự đổi Backlog status.

Chỉ thêm dòng riêng `**Checks:**` ngay sau `**REF:**` khi user hỏi rõ hoặc check có
impact trực tiếp tới finding.
Không ghi pipeline/check vào `**Missing evidence:**` chỉ vì chưa đọc pipeline; chỉ
nhắc khi user/thread hỏi assurance/check status hoặc kết luận phụ thuộc vào
check evidence.

Không thêm dòng `Diff chính` hoặc `Changed files` trong output/`REF`. File
path chỉ nên nằm trong từng finding khi path đó là evidence cần thiết.

Giữ phần `**REF:**` thật ngắn:

- Dùng một dòng duy nhất, không biến thành danh sách nhiều bullet.
- Luôn có `MR` và trạng thái `Backlog`.
- Dùng đúng token `Backlog missing` khi MR description không có mã TRT. Nếu có
  mã TRT nhưng Backlog ticket không đọc được, vẫn ghi Backlog link/key trong
  `**REF:**` và thêm một dòng `**Missing evidence:**` ngắn.
- Chỉ thêm `Design` khi đã đọc design doc/ADR hoặc khi thiếu design REF là
  finding. Không ghi `Design REF: not needed`.
- Dùng đúng token `Design missing` khi design REF là cần thiết nhưng không có.
- Không thêm `Context` mặc định; chỉ đưa context vào finding hoặc kết luận nếu
  nó thật sự đổi phạm vi review.
- Không lặp lại evidence chi tiết trong `REF`; chi tiết nằm trong
  `Location/Evidence` của từng finding.

Nếu không có blocker:

- Giữ section `**Blockers**` và ghi đúng một dòng `Không thấy blocker.`.
- Vẫn nêu recommendations quan trọng và evidence đã đọc.
- Không thêm recommendation kiểu "nên chạy pipeline/CI/local test" chỉ vì
  pipeline vắng mặt.
- Không nói `production-ready` nếu chưa có deploy/eval evidence.

Nếu user chỉ cần summary rất ngắn, giữ format:

```markdown
**Reviewer:** @reviewer | **Implementer:** @implementer
**Kết luận:** <1 câu>.
**Ticket action:** <omit nếu Backlog missing; nếu có TRT, nêu transition/next action theo lifecycle TRT>.
**Findings:** <0-3 bullets quan trọng nhất>.
**REF:** MR <link> | Backlog <TRT link hoặc "missing"> | Design <doc/ADR hoặc "missing"> nếu liên quan
**Missing evidence:** <omit nếu không có>
```

## Safety

- Không tự approve, merge, close, assign, push commit, hoặc trigger destructive
  action nếu user chưa explicit yêu cầu và approval policy chưa cho phép.
- Không tự post GitLab review comment hoặc Mattermost message bằng write tool
  nếu user chưa confirm preview và target.
- Không expose secret value trong output. Nếu phát hiện secret, nêu loại secret,
  file/path và action cần làm; không quote giá trị secret.
- Không claim MR đã deploy hoặc production-ready nếu thiếu evidence tương ứng.
  Chỉ nói safe-to-merge khi đã có đủ evidence cần trước merge; không suy thêm
  deploy hoặc verification sau merge nếu ticket không yêu cầu ở bước review.
- Không biến review thành list nit dài. Ưu tiên issue có risk và next action.

## Verification

Trước khi trả lời:

- Mattermost thread, target MR, implementer/reviewer hoặc phần thiếu đã rõ.
- MR description đã được kiểm tra mã `TRT`; nếu có ticket thì đã đọc Backlog
  ticket context trước khi kết luận.
- Nếu Backlog ticket có status, đã diễn giải status theo lifecycle TRT và tách
  merge readiness khỏi điều kiện còn lại trước `Closed`.
- Claim/finding có GitLab evidence; design claim có source từ `knowledge-search`.
- Nếu MR ảnh hưởng system design, đã đọc design REF từ Agora hoặc ghi ngắn gọn
  là thiếu REF.
- Findings có category, Location/Evidence, impact và next action; không tạo
  finding cho đủ checklist.
- Không thêm pipeline/CI/local test recommendation chỉ vì thiếu pipeline.
- Không thêm `Diff chính`, context dài hoặc danh sách changed files trong
  `Evidence`/`REF`.
- Không thêm confidence score hoặc XML/JSON block vào Mattermost output.
- Không gọi write tool trước khi user confirm target và preview.

## Fixture

Đọc `references/review-fixture.md` khi cần test hoặc demo expected output của
skill này trên một MR fixture.

## Tone & Language

- Ưu tiên từ thông dụng thay vì thuật ngữ kỹ thuật khi có thể.
  Ví dụ: "bên gọi tool" thay vì "caller", "cập nhật lại" thay vì "regenerate",
  "format cũ" thay vì "parallel arrays" hay "legacy schema".
- Không giải thích thuật ngữ inline; nếu cần giải thích thì đổi sang từ khác.
