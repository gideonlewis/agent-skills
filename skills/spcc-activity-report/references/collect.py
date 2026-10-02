#!/usr/bin/env python3
"""Thu thập Mattermost + Backlog trong khung giờ và gom theo ticket report
cho spcc-activity-report.

  collect.py window  [--since S] [--until U]
      Khung [start, end) theo giờ VN + tham số cần cho API.
  collect.py members [--members M]
      Thành viên được lấy: mặc định cả members.json; `--members` là danh sách
      phân tách bằng dấu phẩy (nickname, username Mattermost, backlog_id,
      email) hoặc `backlog_id:username[:nickname]` cho người ngoài file.
  collect.py build   [--since S] [--until U] [--members M]
                     --activities F... [--issues F...] [--mattermost F...]
                     [--children-fetched-for ID,ID...]
      Lọc theo khung + thành viên, gom task con vào ticket cha, chỉ giữ ticket
      thuộc `report_issue_types` (sources.json), gắn thread Mattermost vào
      ticket. In `todo` = những gì còn phải gọi API bổ sung rồi chạy lại.

S/U: `HH:MM` (hôm nay) hoặc `YYYY-MM-DD HH:MM`. Mặc định S = default_since
(05:00), U = bây giờ. File đầu vào là file tool-results (1 JSON, mảng, hoặc
nhiều object nối tiếp) hoặc JSON ghi tay.
"""
import argparse
import json
import re
import sys
import unicodedata
from datetime import datetime, timedelta, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

REF = Path(__file__).resolve().parent
CFG = json.loads((REF / "sources.json").read_text())
TZ = ZoneInfo(CFG["timezone"])
BL, MM = CFG["backlog"], CFG["mattermost"]
REPORT_TYPES = BL["report_issue_types"]
KIND = {1: "created", 2: "updated", 3: "commented", 14: "bulk", 35: "bulk", 50: "related"}
TICKET_RE = re.compile(r"\b(SPCC-\d+|CRES-\d+|chunk[_-]\d+)\b", re.I)
SYSTEM_RE = re.compile(r"^\S+ (added to|removed from) the channel by \S+\.?$|^\S+ (joined|left) the channel\.?$")


# ---------- khung thời gian ----------
def parse_point(s, now):
    s = s.strip().replace("T", " ")
    if re.fullmatch(r"\d{1,2}:\d{2}", s):
        h, m = map(int, s.split(":"))
        return now.replace(hour=h, minute=m, second=0, microsecond=0)
    return datetime.strptime(s, "%Y-%m-%d %H:%M").replace(tzinfo=TZ)


def window(since, until):
    now = datetime.now(TZ).replace(microsecond=0)
    start = parse_point(since or CFG["default_since"], now)
    end = parse_point(until, now) if until else now
    if start >= end:
        sys.exit(f"Khung rỗng: {start:%d/%m %H:%M} → {end:%d/%m %H:%M}.")
    utc = lambda dt: dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    fmt_end = "%H:%M" if start.date() == end.date() else "%d/%m %H:%M"
    return {
        "label": f"{start:%d/%m %H:%M} → {end.strftime(fmt_end)}",
        "start_local": start.isoformat(), "end_local": end.isoformat(),
        "start_utc": utc(start), "end_utc": utc(end),
        "start_ms": int(start.timestamp() * 1000), "end_ms": int(end.timestamp() * 1000),
        "mattermost_since": start.isoformat(),
        # Backlog so ngày theo múi giờ space -> lùi 1 ngày cho chắc không sót.
        "backlog_updated_since": (start.date() - timedelta(days=1)).isoformat(),
        "days": sorted({start.date().isoformat(), end.date().isoformat()}),
    }


# ---------- thành viên ----------
def fold(s):
    s = unicodedata.normalize("NFD", str(s).lower()).replace("đ", "d")
    return "".join(c for c in s if unicodedata.category(c) != "Mn").strip()


def all_members():
    return json.loads((REF / "members.json").read_text())


def resolve_members(spec):
    team = all_members()
    if not spec:
        return team, []
    picked, unknown = [], []
    for tok in [t.strip() for t in spec.split(",") if t.strip()]:
        if re.fullmatch(r"\d+:[\w.\-]+(:.+)?", tok):
            bid, user, *nick = tok.split(":", 2)
            picked.append({"backlog_id": int(bid), "mattermost": user,
                           "nickname": nick[0] if nick else None, "role": None})
            continue
        hits = [m for m in team if fold(tok) in
                {fold(m.get("nickname") or ""), fold(m["mattermost"]), str(m["backlog_id"]),
                 fold(m.get("email") or ""), fold(m["name"])}]
        if len(hits) == 1:
            picked.append(hits[0])
        else:  # không thấy, hoặc mơ hồ (vd "Dũng" khớp 2 người)
            unknown.append({"token": tok, "matches": [m["mattermost"] for m in hits]})
    seen, out = set(), []
    for m in picked:
        if m["backlog_id"] not in seen:
            seen.add(m["backlog_id"])
            out.append(m)
    return out, unknown


def display(m):
    return m.get("nickname") or m["mattermost"]


# ---------- đọc file ----------
def read_values(path):
    text, dec, i, out = Path(path).read_text(), json.JSONDecoder(), 0, []
    while i < len(text):
        while i < len(text) and text[i].isspace():
            i += 1
        if i >= len(text):
            break
        v, i = dec.raw_decode(text, i)
        out.append(v)
    return out


def flatten(v):
    if isinstance(v, list):
        return [y for x in v for y in flatten(x)]
    return [v]


def posts_of(v):
    if isinstance(v, list):
        return [p for x in v for p in posts_of(x)]
    if isinstance(v, dict):
        found = []
        for k in ("posts", "thread", "results", "matches"):
            if isinstance(v.get(k), list):
                found += posts_of(v[k])
        if isinstance(v.get("post"), dict):
            found.append(v["post"])
        if found:
            return found
        if "create_at" in v and "id" in v:
            return [v]
    return []


def norm_ticket(m):
    return re.sub(r"[_-]", "_", m.lower()) if m.lower().startswith("chunk") else m.upper()


def vn_hm(ms=None, iso=None):
    dt = (datetime.fromtimestamp(ms / 1000, TZ) if ms is not None
          else datetime.fromisoformat(iso.replace("Z", "+00:00")).astimezone(TZ))
    return dt.strftime("%H:%M")


# ---------- build ----------
def cmd_build(a):
    w = window(a.since, a.until)
    members, unknown = resolve_members(a.members)
    if unknown:
        sys.exit("Không xác định được thành viên: " + json.dumps(unknown, ensure_ascii=False)
                 + " — dùng `backlog_id:username[:nickname]` hoặc tên cụ thể hơn.")
    by_bid = {m["backlog_id"]: m for m in all_members() + members}
    member_ids = {m["backlog_id"] for m in members}
    member_users = {m["mattermost"] for m in members}
    statuses = json.loads((REF / "spcc-statuses.json").read_text())
    pid, pkey = BL["project_id"], BL["project_key"]
    url = lambda k: f"{BL['space_url']}/view/{k}"

    # Issues (get_issues / get_issue)
    issues = {}
    for f in a.issues or []:
        for x in flatten(read_values(f)):
            if isinstance(x, dict) and x.get("issueKey"):
                issues[x["issueKey"]] = x
    by_id = {x["id"]: x for x in issues.values()}
    itype = lambda x: (x.get("issueType") or {}).get("name")

    missing_keys, missing_parent_ids = set(), set()

    def report_of(key):
        """-> (report_key | None, lý do skip | None). None,None = thiếu dữ liệu."""
        iss = issues.get(key)
        if not iss:
            missing_keys.add(key)
            return None, None
        pid_ = iss.get("parentIssueId")
        if pid_:
            parent = by_id.get(pid_)
            if not parent:
                missing_parent_ids.add(pid_)
                return None, None
            if itype(parent) in REPORT_TYPES:
                return parent["issueKey"], None
        if itype(iss) in REPORT_TYPES:
            return key, None
        return None, ("task con của ticket không thuộc loại report" if pid_ else "task không có ticket cha")

    # Activities
    raw = {}
    for f in a.activities:
        for x in flatten(read_values(f)):
            if isinstance(x, dict) and "createdUser" in x:
                raw[x["id"]] = x
    paging = []
    for bid in member_ids:
        mine = [x for x in raw.values() if x["createdUser"]["id"] == bid]
        if len(mine) >= 100:
            oldest = min(mine, key=lambda x: x["id"])
            if oldest["created"] >= w["start_utc"]:
                paging.append({"backlog_id": bid, "max_id": oldest["id"] - 1})
    fetched_ids = {x["createdUser"]["id"] for x in raw.values()}

    acts = []
    for x in sorted(raw.values(), key=lambda x: x["created"]):
        if x["project"]["id"] != pid or x["createdUser"]["id"] not in member_ids:
            continue
        if not (w["start_utc"] <= x["created"] < w["end_utc"]):
            continue
        c = x.get("content") or {}
        keys = [c.get("key_id") or c.get("keyId")] + [l.get("key_id") for l in c.get("link") or []]
        keys = [f"{pkey}-{k}" for k in keys if k]
        if not keys:  # Document, Wiki...
            continue
        changes = []
        for ch in c.get("changes") or []:
            field = ch.get("field_text") or ch.get("field")
            old, new = ch.get("old_value"), ch.get("new_value")
            if (field or "").lower() == "status":
                field, old, new = "Status", statuses.get(str(old), old), statuses.get(str(new), new)
            changes.append({"field": field, "from": old, "to": new})
        comment = ((c.get("comment") or {}).get("content") or "").strip()
        for k in keys:
            acts.append({"at": vn_hm(iso=x["created"]), "at_utc": x["created"],
                         "by": display(by_bid[x["createdUser"]["id"]]),
                         "type": KIND.get(x["type"], f"other({x['type']})"), "key": k,
                         "changes": changes, "comment": comment[:600] or None})

    # Mattermost
    rawp = {}
    for f in a.mattermost or []:
        for v in read_values(f):
            for p in posts_of(v):
                rawp[p["id"]] = p
    allp = list(rawp.values())
    bots = set(MM["bots"])
    keep = [p for p in allp
            if w["start_ms"] <= p["create_at"] < w["end_ms"]
            and not (p.get("type") or "").startswith("system_")
            and not SYSTEM_RE.match(p.get("message") or "")
            and p.get("username") not in bots
            and not any((p.get("message") or "").lstrip().startswith(f"@{b}") for b in bots)
            and p.get("username") in member_users]
    texts = {(p.get("username"), p["create_at"]) for p in keep if p.get("message")}
    keep = [p for p in keep if p.get("message") or (p.get("username"), p["create_at"]) not in texts]
    in_ids = {p["id"] for p in keep}
    nick_of = {m["mattermost"]: display(m) for m in all_members() + members}
    groups = {}
    for p in sorted(keep, key=lambda p: p["create_at"]):
        groups.setdefault(p.get("root_id") or p["id"], []).append(p)
    threads, roots_to_read = [], []
    for root, ps in groups.items():
        rp = rawp.get(root)
        if root not in in_ids and not rp:
            roots_to_read.append(root)
        root_msg = None if root in in_ids or not rp else (rp.get("message") or "")[:500]
        text = [p.get("message") or "" for p in ps] + [root_msg or ""]
        threads.append({
            "root_id": root, "root_in_window": root in in_ids, "root_message": root_msg,
            "tickets": sorted({norm_ticket(m) for t in text for m in TICKET_RE.findall(t)}),
            "posts": [{"at": vn_hm(ms=p["create_at"]), "user": nick_of.get(p.get("username"), p.get("username")),
                       "message": p.get("message") or "[đính kèm]"} for p in ps],
        })
    oldest = min((p["create_at"] for p in allp), default=None)
    mm_truncated = len(allp) >= 100 and oldest is not None and oldest > w["start_ms"]

    # Gom theo ticket report
    tickets, skipped = {}, {}

    def ticket(k):
        if k not in tickets:
            iss = issues[k]
            asg = (iss.get("assignee") or {})
            tickets[k] = {"key": k, "url": url(k), "issue_type": itype(iss), "summary": iss.get("summary"),
                          "status_now": (iss.get("status") or {}).get("name"),
                          "assignee": display(by_bid[asg["id"]]) if asg.get("id") in by_bid else asg.get("name"),
                          "id": iss["id"], "activities": [], "children": {}, "threads": [], "last_at": ""}
        return tickets[k]

    for r in acts:
        rk, why = report_of(r["key"])
        if why:
            iss = issues[r["key"]]
            skipped.setdefault(r["key"], {"key": r["key"], "issue_type": itype(iss),
                                          "summary": iss.get("summary"), "reason": why})
        if not rk:
            continue
        t = ticket(rk)
        t["last_at"] = max(t["last_at"], r["at_utc"])
        item = {k: v for k, v in r.items() if k not in ("key", "at_utc")}
        if r["key"] == rk:
            t["activities"].append(item)
        else:
            t["children"].setdefault(r["key"], []).append(item)

    # Mã CRES-/chunk_N: tìm trong summary của ticket loại report.
    def by_text(tk):
        pat = re.compile(r"(?<![\w])" + re.escape(tk).replace("_", "[_-]") + r"(?!\d)", re.I)
        return [k for k, x in issues.items() if itype(x) in REPORT_TYPES and pat.search(x.get("summary") or "")]

    unmapped = []
    for th in threads:
        targets, rest = set(), []
        for tk in th["tickets"]:
            cand = [tk] if tk.startswith(pkey + "-") else by_text(tk)
            got = False
            for k in cand:
                rk, _ = report_of(k)
                if rk:
                    targets.add(rk)
                    got = True
            if not got:
                rest.append(tk)
        for rk in targets:
            ticket(rk)["threads"].append(th)
        if not targets:
            unmapped.append(dict(th, unresolved_tickets=rest))

    # Toàn bộ task con đã biết của từng ticket report (kể cả không có activity).
    for t in tickets.values():
        kids = {x["issueKey"]: x for x in issues.values() if x.get("parentIssueId") == t["id"]}
        t["children"] = [
            {"key": k, "issue_type": itype(x), "summary": x.get("summary"),
             "status_now": (x.get("status") or {}).get("name"),
             "assignee": display(by_bid[(x.get("assignee") or {}).get("id")])
                         if (x.get("assignee") or {}).get("id") in by_bid else (x.get("assignee") or {}).get("name"),
             "activities": t["children"].get(k, [])}
            for k, x in sorted(kids.items())
        ] + [{"key": k, "issue_type": None, "summary": None, "status_now": None, "assignee": None, "activities": v}
             for k, v in t["children"].items() if k not in kids]

    for t in tickets.values():
        summary = {}
        for c in t["children"]:
            if c["status_now"]:
                summary[c["status_now"]] = summary.get(c["status_now"], 0) + 1
        t["children_status"] = summary
        t["children_active"] = [c["key"] for c in t["children"] if c["activities"]]
    done_children = {int(x) for x in (a.children_fetched_for or "").split(",") if x.strip()}

    order = {n: i for i, n in enumerate(REPORT_TYPES)}
    out_tickets = sorted(tickets.values(), key=lambda t: (order.get(t["issue_type"], 99), t["key"]))
    for t in out_tickets:
        t.pop("last_at")

    print(json.dumps({
        "window": w,
        "members": [display(m) for m in members],
        "report_issue_types": REPORT_TYPES,
        "counts": {"activities": len(acts), "posts": len(keep), "threads": len(threads),
                   "tickets": len(out_tickets), "skipped": len(skipped), "unmapped_threads": len(unmapped)},
        "todo": {
            "members_not_fetched": sorted(member_ids - fetched_ids),
            "members_need_paging": paging,
            "missing_issue_keys": sorted(missing_keys),
            "missing_parent_issue_ids": sorted(missing_parent_ids),
            "fetch_children_for_issue_ids": [t["id"] for t in out_tickets if t["id"] not in done_children],
            "roots_to_read": roots_to_read,
            "mattermost_possibly_truncated": mm_truncated,
        },
        "tickets": out_tickets,
        "skipped": list(skipped.values()),
        "unmapped_threads": unmapped,
    }, ensure_ascii=False))


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("window"); c.add_argument("--since"); c.add_argument("--until")
    c = sub.add_parser("members"); c.add_argument("--members")
    c = sub.add_parser("build")
    c.add_argument("--since"); c.add_argument("--until"); c.add_argument("--members")
    c.add_argument("--activities", nargs="+", required=True)
    c.add_argument("--issues", nargs="*"); c.add_argument("--mattermost", nargs="*")
    c.add_argument("--children-fetched-for", help="id các ticket report đã gọi get_issues(parent_issue_ids) xong")
    a = p.parse_args()
    if a.cmd == "window":
        print(json.dumps(window(a.since, a.until), ensure_ascii=False, indent=2))
    elif a.cmd == "members":
        ms, unknown = resolve_members(a.members)
        print(json.dumps({"members": [{"backlog_id": m["backlog_id"], "mattermost": m["mattermost"],
                                       "display": display(m)} for m in ms],
                          "unknown": unknown}, ensure_ascii=False, indent=2))
    else:
        cmd_build(a)


if __name__ == "__main__":
    main()
