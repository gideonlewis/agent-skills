# Lọc post Mattermost (kết quả mattermost-read_channel) về đúng khung thời
# gian và gom theo thread.
#
#   jq -s -c --argjson start "$START_MS" --argjson end "$END_MS" \
#      -f mattermost-posts.jq <file đã lưu>
#
# Lọc theo create_at (KHÔNG theo update_at): tham số `since` của API trả về cả
# post cũ vừa được sửa/được reply, nên phải lọc lại ở đây.
# Bỏ system message (thêm/rời channel...). Post rỗng (chỉ có file/ảnh) giữ lại
# với message "[đính kèm]" để không mất dấu ai đó đã gửi evidence.
#
# Output: {count, truncated_hint, threads: [{root_id, root_in_window, posts:[...]}]}
#   root_in_window=false nghĩa là thread bắt đầu trước khung — chỉ các reply
#   trong khung được đưa vào; cần read_post(root_id) nếu muốn biết chủ đề.

def is_system:
  (.type // "" | startswith("system_"))
  or (.message | test("^\\S+ (added to|removed from) the channel by \\S+\\.?$|^\\S+ (joined|left) the channel\\.?$"));

(map(.posts // .) | flatten) as $all
| ($all | map(select(.create_at >= $start and .create_at < $end and (is_system | not)))
        | unique_by(.id)) as $posts
| ($posts | map(.id)) as $ids
| {
    count: ($posts | length),
    # read_channel trả tối đa 100 post; nếu chạm trần mà post cũ nhất vẫn ở
    # sau start thì có thể đã bị cắt -> cần bổ sung bằng search_posts.
    raw_count: ($all | length),
    oldest_raw_ms: ($all | map(.create_at) | min),
    threads: (
      $posts
      | map(. + {thread: (if ((.root_id // "") == "") then .id else .root_id end)})
      | group_by(.thread)
      | map({
          root_id: .[0].thread,
          root_in_window: (.[0].thread as $t | $ids | index($t) != null),
          first_at: (map(.create_at) | min),
          posts: (sort_by(.create_at) | map({
            at: (.create_at / 1000 | strflocaltime("%H:%M")),
            user: .username,
            message: (if .message == "" then "[đính kèm]" else .message end)
          }))
        })
      | sort_by(.first_at)
    )
  }
