# Rút gọn activity Backlog (kết quả get_user_recent_updates) về đúng khung
# thời gian và đúng project, bỏ phần description/metadata nặng.
#
#   jq -s -c --arg start "$START_UTC" --arg end "$END_UTC" \
#      --argjson pid 149054 --arg pkey SPCC \
#      --slurpfile st spcc-statuses.json \
#      -f backlog-activities.jq <file đã lưu> ...
#
# `st` là map status id -> tên (Backlog trả Status dạng id trong activity).
# Project khác SPCC: tạo file tương tự từ get_status_list_of_project.
#
# Nhận nhiều file cùng lúc (mỗi file là chuỗi object JSON nối tiếp nhau, nên
# phải dùng -s). So sánh chuỗi ISO UTC là đủ vì cùng format "...Z".
#
# Output: mảng các dòng {at, by, type, keys, summary, changes, comment}.
#   type: created | updated | commented | bulk | related | other(<id>)

def kind:
  {"1": "created", "2": "updated", "3": "commented", "14": "bulk",
   "35": "bulk", "50": "related"}[tostring] // "other(\(.))";

def issue_key($pkey; $kid): if $kid == null then null else "\($pkey)-\($kid)" end;

flatten
| map(select(.project.id == $pid and .created >= $start and .created < $end))
| unique_by(.id)
| map(
    . as $a
    | ($a.content) as $c
    | {
        at: $a.created,
        by: $a.createdUser.name,
        type: ($a.type | kind),
        keys: (
          [issue_key($pkey; $c.key_id // $c.keyId)]
          + [($c.link // [])[] | issue_key($pkey; .key_id)]
          + (if $c.relatedIssue then [$c.relatedIssue.key] else [] end)
          | map(select(. != null))
        ),
        summary: ($c.summary // (($c.link // [])[0].title) // null),
        changes: [
          ($c.changes // [])[]
          | (.field_text // .field) as $f
          | if ($f | ascii_downcase) == "status"
            then {field: "Status", from: ($st[0][.old_value] // .old_value),
                  to: ($st[0][.new_value] // .new_value)}
            else {field: $f, from: .old_value, to: .new_value} end
        ],
        comment: (($c.comment.content // "") | if . == "" then null else .[:600] end)
      }
  )
# Bỏ activity không gắn ticket (tạo/sửa Document, Wiki...), ví dụ chính lượt
# đăng brief lên Backlog Document hôm trước.
| map(select(.keys | length > 0))
| sort_by(.at)
