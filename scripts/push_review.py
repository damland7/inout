#!/usr/bin/env python3
"""Review real commit counts and require an exact, short-lived push approval."""
import argparse
from collections import Counter
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import unicodedata

TEAM_MEMBERS = (
    ("Hüseyin Vakkasoğlu", "huseyinvk"),
    ("Damla Kandemir", "damland7"),
    ("Berre Özçanak", "berreozcanak"),
    ("Bedirhan Ceylan", "bedirhancceylan"),
)

def git(*args, strip=True):
    output = subprocess.check_output(["git", *args], text=True)
    return output.strip() if strip else output

def push_destination():
    urls = git("remote", "get-url", "--push", "--all", "origin").splitlines()
    if len(urls) != 1:
        raise ValueError("Review requires exactly one push URL for origin.")
    return {"remote_name": "origin", "push_url": urls[0]}

def commit_details(*revisions):
    rows = git("log", "--reverse", "--format=%H%x00%an <%ae>%x00%s", *revisions, "--")
    return [dict(zip(("sha", "author", "subject"), row.split("\0", 2)))
        for row in rows.splitlines()] if rows else []

def normalized(value):
    return "".join(char for char in unicodedata.normalize("NFKD", value.casefold())
        if not unicodedata.combining(char))

def team_history(base_sha):
    refs = git("for-each-ref", "--format=%(refname)",
        "refs/heads", "refs/remotes").splitlines()
    commits = commit_details(*refs, "--not", base_sha)
    counts = Counter()
    unmapped = Counter()
    for commit in commits:
        name, _, email = commit["author"].rpartition(" <")
        email = email.rstrip(">")
        local, _, domain = email.rpartition("@")
        if domain.casefold() == "users.noreply.github.com":
            local = local.rsplit("+", 1)[-1]
        matches = [username for member_name, username in TEAM_MEMBERS
            if normalized(name) in (normalized(member_name), username)
            or local.casefold() == username]
        if len(matches) == 1:
            counts[matches[0]] += 1
        else:
            unmapped[commit["author"]] += 1
    return {
        "team": [{"name": name, "username": username, "count": counts[username]}
            for name, username in TEAM_MEMBERS],
        "team_commit_count": len(commits),
        "unmapped_authors": dict(unmapped),
        "team_refs": refs,
        "team_scope": "Unique commits reachable from local and fetched remote branches, excluding base ancestors.",
    }

def collect(base):
    branch = git("symbolic-ref", "--quiet", "--short", "HEAD")
    head = git("rev-parse", "HEAD")
    base_sha = git("rev-parse", "--verify", base + "^{commit}")
    git("merge-base", "--is-ancestor", base_sha, head)
    commits = commit_details(base_sha + "..HEAD")
    remote_ref = "refs/remotes/origin/" + branch
    remote = subprocess.run(["git", "rev-parse", "--verify", remote_ref],
        text=True, capture_output=True)
    return {
        "branch": branch, "head": head, "base": base, "base_sha": base_sha,
        "count": len(commits),
        "outgoing_count": int(git("rev-list", "--count", "HEAD", "--not", "--remotes=origin")),
        "authors": dict(Counter(commit["author"] for commit in commits)),
        "commits": commits,
        "changed_paths": git("diff", "--no-ext-diff", "--no-textconv", "--name-status", base_sha, head, "--"),
        "diff_stat": git("diff", "--no-ext-diff", "--no-textconv", "--stat", base_sha, head, "--"),
        "diff": git("diff", "--no-ext-diff", "--no-textconv", "--no-color", "--binary", base_sha, head, "--", strip=False),
        "remote_tip": remote.stdout.strip() if remote.returncode == 0 else "0" * 40,
        "dirty": bool(git("status", "--porcelain")),
        "author": git("var", "GIT_AUTHOR_IDENT").split(">")[0] + ">",
        **push_destination(),
        **team_history(base_sha),
    }

def approval_path():
    return Path(git("rev-parse", "--git-path", "inout-push-approval.json"))

def show(report, fresh):
    report["fresh_remote"] = fresh
    report["ref_freshness"] = {
        "origin": "freshly fetched" if fresh else "cached",
        "other_remotes": "cached",
        "local_branches": "local",
    }
    print(json.dumps({key: value for key, value in report.items() if key != "diff"},
        indent=2, ensure_ascii=False))
    print("Commit count records history; it does not establish contribution quality or a grade.")
    print("Eventual team target: 8 meaningful commits/member; max-min <= 1.")
    print("This is a final team goal, not a prerequisite for the first member's push.")
    print("Never create empty, backdated or cosmetic-only commits to raise it.")
    print("Counts do not establish whether commits are meaningful; review the work.")
    print("\nChanged paths:\n" + report["changed_paths"])
    print("\nDiff stat:\n" + report["diff_stat"])
    print("\nBranch diff:\n" + report["diff"])

def record(base):
    subprocess.run(["git", "fetch", "--prune", "origin",
        "+refs/heads/*:refs/remotes/origin/*"], check=True)
    report = collect(base)
    show(report, True)
    if report["dirty"]:
        raise ValueError("Commit or preserve your changes first; working tree must be clean.")
    if report["count"] <= 0:
        raise ValueError("No feature commits to review.")
    flutter = os.environ.get("INOUT_FLUTTER") or shutil.which("flutter")
    if not flutter:
        raise ValueError("Flutter is not on PATH.")
    for command in [[flutter, "analyze", "--no-pub"], [flutter, "test", "--no-pub"]]:
        subprocess.run(command, check=True)
    token = f'{report["branch"]}@{report["head"][:7]} {report["count"]}'
    print("Review the authors, diff and counts above. Approve ONLY this branch/SHA.")
    if input("To approve, type " + token + ": ").strip() != token:
        raise ValueError("Approval was not given; push stays blocked.")
    approval_path().write_text(json.dumps({**report, "created": time.time()}))
    print("Approved for 10 minutes. Ordinary git push still passes through the hook.")

def check_hook(remote_name, remote_url):
    path = approval_path()
    if not path.exists():
        raise ValueError("No push review. Run python3 scripts/push_review.py --record --base YOUR_BASE.")
    approved = json.loads(path.read_text())
    if not 0 <= time.time() - approved["created"] <= 600:
        raise ValueError("Push review expired. Review again.")
    if (remote_name != "origin" or remote_name != approved.get("remote_name")
            or remote_url != approved.get("push_url")):
        raise ValueError("Push destination differs from the reviewed origin remote and URL.")
    current = collect(approved["base"])
    if any(current[key] != approved[key] for key in ("remote_name", "push_url")):
        raise ValueError("Configured push destination changed. Review again.")
    for key in ["branch", "head", "base_sha", "count", "author"]:
        if current[key] != approved[key]:
            raise ValueError("Branch, SHA, author or commit count changed. Review again.")
    if current["dirty"]:
        raise ValueError("Working tree changed after review.")
    updates = [line.split() for line in sys.stdin if line.strip()]
    if len(updates) != 1 or len(updates[0]) != 4:
        raise ValueError("Review approves exactly one branch, not tags/deletions/multiple refs.")
    local_ref, local_sha, remote_ref, remote_sha = updates[0]
    expected_ref = "refs/heads/" + approved["branch"]
    if local_ref != expected_ref or remote_ref != expected_ref or local_sha != approved["head"]:
        raise ValueError("Push target differs from the reviewed branch.")
    if remote_sha != approved["remote_tip"]:
        raise ValueError("Remote branch changed after review. Fetch and review again.")
    print(f'Push check: {approved["count"]} task commits; author {approved["author"]}.')
    path.unlink()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--record", action="store_true")
    mode.add_argument("--check-hook", action="store_true")
    mode.add_argument("--local", action="store_true")
    parser.add_argument("--base", default="origin/main")
    parser.add_argument("--remote-name")
    parser.add_argument("--remote-url")
    args = parser.parse_args()
    try:
        if args.check_hook:
            check_hook(args.remote_name, args.remote_url)
        elif args.record:
            record(args.base)
        else:
            show(collect(args.base), False)
            print("Local/cached refs only. This does NOT authorize a push.")
        return 0
    except (subprocess.CalledProcessError, ValueError, OSError, EOFError, KeyError) as error:
        print("Push blocked: " + str(error), file=sys.stderr)
        return 1

if __name__ == "__main__":
    raise SystemExit(main())
