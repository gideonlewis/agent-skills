#!/usr/bin/env python3
"""Kho dữ liệu đã lọc theo từng ngày lịch cho spcc-daily-brief.

Mặc định lưu ở ~/.cache/spc-collab-daily (đổi bằng biến môi trường
SPC_DAILY_STORE). Không để trong repo agent-skills: đây là dữ liệu nội bộ.

  store.py check [--refresh] DAY...
      In {"cached": [...], "missing": [...]} — ngày nào dùng lại được.
  store.py ingest DAY --backlog F... [--mattermost F...] [--user-stories F...] [--truncated]
      Lọc file thô (tool-results) về đúng DAY rồi ghi <store>/<DAY>/.
  store.py load DAY...
      In JSON gộp các ngày để viết brief.
  store.py save-brief LABEL FILE
      Lưu brief đã viết vào <store>/briefs/<LABEL>.md.
  store.py published LABEL [--doc-id ID --url URL]
      Đọc / ghi thông tin trang Backlog Document đã đăng cho LABEL.

DAY dạng YYYY-MM-DD. Một ngày được coi là dùng lại được khi đã ingest sau
khi ngày đó kết thúc, không bị cắt dữ liệu, và danh sách member không đổi.
"""
import argparse
import json
import os
import subprocess
import sys
from datetime import date, datetime, time, timedelta, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

TZ = ZoneInfo("Asia/Ho_Chi_Minh")
REF = Path(__file__).resolve().parent
STORE = Path(os.environ.get("SPC_DAILY_STORE", Path.home() / ".cache" / "spc-collab-daily"))
PROJECT_ID, PROJECT_KEY = 149054, "SPCC"


def day_window(day: str):
    d = date.fromisoformat(day)
    start = datetime.combine(d, time(0, 0), tzinfo=TZ)
    end = start + timedelta(days=1)
    utc = lambda dt: dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    return {"start_utc": utc(start), "end_utc": utc(end),
            "start_ms": int(start.timestamp() * 1000), "end_ms": int(end.timestamp() * 1000),
            "end": end}


def member_ids():
    return sorted(m["backlog_id"] for m in json.loads((REF / "members.json").read_text()))


def jq(args, files):
    if not files:
        return None
    out = subprocess.run(["jq", "-s", "-c", *args, *files], capture_output=True, text=True,
                         env={**os.environ, "TZ": "Asia/Ho_Chi_Minh"})
    if out.returncode != 0:
        sys.exit(f"jq lỗi: {out.stderr.strip()}")
    return json.loads(out.stdout)


def cmd_check(a):
    cached, missing = [], []
    for day in a.days:
        meta_f = STORE / day / "meta.json"
        ok = False
        if meta_f.exists() and not a.refresh:
            meta = json.loads(meta_f.read_text())
            ok = (datetime.fromisoformat(meta["fetched_at"]) >= day_window(day)["end"]
                  and not meta.get("truncated")
                  and meta.get("members") == member_ids())
        (cached if ok else missing).append(day)
    print(json.dumps({"store": str(STORE), "cached": cached, "missing": missing}))


def cmd_ingest(a):
    w, d = day_window(a.day), STORE / a.day
    d.mkdir(parents=True, exist_ok=True)
    backlog = jq(["--arg", "start", w["start_utc"], "--arg", "end", w["end_utc"],
                  "--argjson", "pid", str(PROJECT_ID), "--arg", "pkey", PROJECT_KEY,
                  "--slurpfile", "st", str(REF / "spcc-statuses.json"),
                  "-f", str(REF / "backlog-activities.jq")], a.backlog) or []
    ids = set(member_ids())
    mm = jq(["--argjson", "start", str(w["start_ms"]), "--argjson", "end", str(w["end_ms"]),
             "-f", str(REF / "mattermost-posts.jq")], a.mattermost)
    us_keys = set(jq(["[.[].issueKey]"], a.user_stories) or [])
    us_status = [
        {"at": r["at"], "key": r["keys"][0], "summary": r["summary"], "by": r["by"],
         "from": c["from"], "to": c["to"]}
        for r in backlog if r["keys"] and r["keys"][0] in us_keys
        for c in r["changes"] if c["field"] == "Status"
    ]
    (d / "backlog.json").write_text(json.dumps(backlog, ensure_ascii=False))
    (d / "mattermost.json").write_text(json.dumps(mm or {"count": 0, "threads": []}, ensure_ascii=False))
    (d / "user-stories.json").write_text(json.dumps(us_status, ensure_ascii=False))
    meta = {"day": a.day, "fetched_at": datetime.now(TZ).isoformat(), "members": sorted(ids),
            "truncated": a.truncated, "backlog_count": len(backlog),
            "mattermost_count": (mm or {}).get("count", 0), "user_story_changes": len(us_status)}
    (d / "meta.json").write_text(json.dumps(meta, ensure_ascii=False, indent=2))
    print(json.dumps(meta, ensure_ascii=False))


def cmd_load(a):
    out = {"days": a.days, "backlog": [], "mattermost_threads": [], "user_story_status": [], "meta": []}
    for day in a.days:
        d = STORE / day
        if not (d / "meta.json").exists():
            sys.exit(f"Chưa có dữ liệu ngày {day} — chạy ingest trước.")
        out["meta"].append(json.loads((d / "meta.json").read_text()))
        out["backlog"] += json.loads((d / "backlog.json").read_text())
        out["mattermost_threads"] += [dict(t, day=day) for t in json.loads((d / "mattermost.json").read_text())["threads"]]
        out["user_story_status"] += json.loads((d / "user-stories.json").read_text())
    print(json.dumps(out, ensure_ascii=False))


def _label_file(label, ext):
    (STORE / "briefs").mkdir(parents=True, exist_ok=True)
    return STORE / "briefs" / f"{label.replace(' ', '').replace('→', '_to_')}{ext}"


def cmd_save_brief(a):
    f = _label_file(a.label, ".md")
    f.write_text(Path(a.file).read_text())
    print(f)


def cmd_published(a):
    f = _label_file(a.label, ".published.json")
    if a.doc_id:
        f.write_text(json.dumps({"label": a.label, "doc_id": a.doc_id, "url": a.url,
                                 "published_at": datetime.now(TZ).isoformat()}, ensure_ascii=False))
    print(f.read_text() if f.exists() else "null")


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("check"); c.add_argument("--refresh", action="store_true"); c.add_argument("days", nargs="+")
    c = sub.add_parser("ingest"); c.add_argument("day")
    c.add_argument("--backlog", nargs="+", required=True); c.add_argument("--mattermost", nargs="*", default=[])
    c.add_argument("--user-stories", nargs="*", default=[]); c.add_argument("--truncated", action="store_true")
    c = sub.add_parser("load"); c.add_argument("days", nargs="+")
    c = sub.add_parser("save-brief"); c.add_argument("label"); c.add_argument("file")
    c = sub.add_parser("published"); c.add_argument("label"); c.add_argument("--doc-id"); c.add_argument("--url")
    a = p.parse_args()
    {"check": cmd_check, "ingest": cmd_ingest, "load": cmd_load,
     "save-brief": cmd_save_brief, "published": cmd_published}[a.cmd](a)


if __name__ == "__main__":
    main()
