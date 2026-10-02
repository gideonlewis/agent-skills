#!/usr/bin/env python3
"""Tính khung thời gian [start, end) cho daily brief.

Cách dùng:
  python3 window.py                 # hôm nay theo giờ VN -> khung của "ngày làm việc trước"
  python3 window.py 2026-09-29      # coi như hôm nay là 2026-09-29
  python3 window.py --day 2026-09-25  # lấy đúng 1 ngày 2026-09-25 (không gộp cuối tuần)

Quy tắc mặc định (ngày làm việc trước):
  - Thứ 3..Thứ 6: khung = cả ngày hôm qua.
  - Thứ 2: khung = Thứ 6 00:00 -> Thứ 2 00:00 (gộp Thứ 6 + Thứ 7 + CN).
  - Thứ 7 / CN: khung = Thứ 6 (ngày làm việc gần nhất), đến 00:00 hôm nay.
  end luôn là 00:00 của "hôm nay" (không lấy dữ liệu hôm nay), trừ chế độ --day.

In ra JSON với start/end ở 3 dạng: giờ VN, UTC ISO (so với Backlog `created`),
epoch ms (so với Mattermost `create_at`), và danh sách ngày trong khung.
"""
import json
import sys
from datetime import date, datetime, time, timedelta, timezone
from zoneinfo import ZoneInfo

TZ = ZoneInfo("Asia/Ho_Chi_Minh")


def at_midnight(d: date) -> datetime:
    return datetime.combine(d, time(0, 0), tzinfo=TZ)


def main(argv):
    single_day = False
    if argv and argv[0] == "--day":
        single_day = True
        argv = argv[1:]
    today = date.fromisoformat(argv[0]) if argv else datetime.now(TZ).date()

    if single_day:
        start_day, end_day = today, today + timedelta(days=1)
    else:
        wd = today.weekday()  # Mon=0 .. Sun=6
        back = {0: 3, 5: 1, 6: 2}.get(wd, 1)
        start_day, end_day = today - timedelta(days=back), today

    start, end = at_midnight(start_day), at_midnight(end_day)
    utc = lambda dt: dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    days = [(start_day + timedelta(days=i)).isoformat()
            for i in range((end_day - start_day).days)]
    print(json.dumps({
        "label": days[0] if len(days) == 1 else f"{days[0]} → {days[-1]}",
        "days": days,
        "start_local": start.isoformat(),
        "end_local": end.isoformat(),
        "start_utc": utc(start),
        "end_utc": utc(end),
        "start_ms": int(start.timestamp() * 1000),
        "end_ms": int(end.timestamp() * 1000),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main(sys.argv[1:])
