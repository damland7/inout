import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
import unittest

SCRIPT = Path(__file__).parents[1] / "scripts" / "push_review.py"
HOOK = SCRIPT.parents[1] / ".githooks" / "pre-push"

class PushReviewTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / "repo"
        self.repo.mkdir()
        self.run_git("init", "-q", "-b", "main")
        self.run_git("config", "user.name", "Fixture Student")
        self.run_git("config", "user.email", "fixture@example.test")
        (self.repo / "file").write_text("base")
        self.run_git("add", "file")
        self.run_git("commit", "-qm", "base")
        self.origin = self.root / "origin.git"
        subprocess.run(["git", "init", "-q", "--bare", str(self.origin)], check=True)
        self.run_git("remote", "add", "origin", str(self.origin))
        self.run_git("push", "-q", "origin", "main")
        self.run_git("update-ref", "refs/remotes/origin/main", "HEAD")
        self.run_git("switch", "-qc", "feature/test")
        (self.repo / "file").write_text("feature")
        self.run_git("commit", "-qam", "real feature")

    def run_git(self, *args):
        return subprocess.check_output(["git", "-C", str(self.repo), *args],
            text=True, stderr=subprocess.DEVNULL).strip()

    def run_script(self, *args, data="", env=None):
        return subprocess.run(["python3", str(SCRIPT), *args], cwd=self.repo,
            input=data, text=True, capture_output=True, env=env)

    def run_hook(self, report, remote="origin", url=None, data=None):
        return self.run_script("--check-hook", "--remote-name", remote,
            "--remote-url", str(url or self.origin),
            data=self.update_line(report) if data is None else data)

    def record(self):
        flutter = self.root / "flutter"
        flutter.write_text("#!/bin/sh\nexit 0\n")
        flutter.chmod(0o755)
        token = f'feature/test@{self.run_git("rev-parse", "--short=7", "HEAD")} 1'
        return self.run_script("--record", data=token + "\n",
            env={**os.environ, "INOUT_FLUTTER": str(flutter)})

    def commit_as(self, name, email, text, subject):
        (self.repo / "file").write_text(text)
        self.run_git("-c", "user.name=" + name, "-c", "user.email=" + email,
            "commit", "-qam", subject)
        return self.run_git("rev-parse", "HEAD")

    def report(self):
        result = self.run_script("--local")
        self.assertEqual(result.returncode, 0, result.stderr)
        raw = result.stdout[:result.stdout.index("\nCommit count")]
        return json.loads(raw)

    def approve_fixture(self):
        report = self.report()
        report["created"] = time.time()
        path = self.repo / ".git" / "inout-push-approval.json"
        path.write_text(json.dumps(report))
        return path, report

    def update_line(self, report, remote=None):
        ref = "refs/heads/" + report["branch"]
        return f'{ref} {report["head"]} {ref} {remote or report["remote_tip"]}\n'

    def test_counts_real_feature_commits_separately_from_base(self):
        report = self.report()
        self.assertEqual(report["count"], 1)
        self.assertEqual(report["outgoing_count"], 1)
        self.assertEqual(report["authors"], {"Fixture Student <fixture@example.test>": 1})

    def test_report_contains_full_commit_and_readable_diff_evidence(self):
        report = self.report()
        self.assertEqual(report["commits"], [{
            "sha": self.run_git("rev-parse", "HEAD"),
            "author": "Fixture Student <fixture@example.test>",
            "subject": "real feature",
        }])
        self.assertEqual(report["changed_paths"], "M\tfile")
        self.assertIn("file |", report["diff_stat"])
        output = self.run_script("--local").stdout
        self.assertIn("diff --git a/file b/file\n", output)
        self.assertIn("-base\n", output)
        self.assertIn("+feature\n", output)

    def test_displayed_diff_preserves_trailing_spaces_on_final_added_line(self):
        (self.repo / "file").write_text("feature   \n")
        self.run_git("commit", "-qam", "preserve exact content")
        result = self.run_script("--local")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("+feature   \n", result.stdout)

    def test_counts_unique_teammate_commits_across_available_branch_refs(self):
        self.run_git("switch", "-qc", "feature/damla", "origin/main")
        damla_sha = self.commit_as("Damla Kandemir", "damland7@example.test",
            "damla", "build feed")
        self.run_git("update-ref", "refs/remotes/origin/feature/damla", damla_sha)
        self.run_git("switch", "-qc", "feature/berre", "origin/main")
        self.commit_as("GitHub User", "123+berreozcanak@users.noreply.github.com",
            "berre", "build profile")
        self.run_git("update-ref", "refs/remotes/teammate/feature/berre", "HEAD")
        self.run_git("switch", "-q", "feature/test")
        self.run_git("branch", "-D", "feature/berre")
        report = self.report()
        counts = {member["username"]: member["count"] for member in report["team"]}
        self.assertEqual(counts, {"huseyinvk": 0, "damland7": 1,
            "berreozcanak": 1, "bedirhancceylan": 0})
        self.assertEqual(report["count"], 1)
        self.assertEqual(report["unmapped_authors"],
            {"Fixture Student <fixture@example.test>": 1})
        self.assertEqual(report["team_commit_count"], 3)
        self.assertFalse(report["fresh_remote"])
        self.assertEqual(report["ref_freshness"]["other_remotes"], "cached")

    def test_team_name_aliases_map_without_counting_base_commit(self):
        self.run_git("-c", "user.name=Hüseyin Vakkasoğlu", "-c",
            "user.email=private@example.test", "commit", "--amend", "--reset-author", "--no-edit", "-q")
        self.commit_as("bedirhancceylan", "private@example.test", "bedirhan", "add flow")
        report = self.report()
        names = {member["username"]: member["name"] for member in report["team"]}
        counts = {member["username"]: member["count"] for member in report["team"]}
        self.assertEqual(names, {"huseyinvk": "Hüseyin Vakkasoğlu",
            "damland7": "Damla Kandemir", "berreozcanak": "Berre Özçanak",
            "bedirhancceylan": "Bedirhan Ceylan"})
        self.assertEqual(counts["huseyinvk"], 1)
        self.assertEqual(counts["bedirhancceylan"], 1)
        self.assertEqual(report["team_commit_count"], 2)
        self.assertEqual(report["unmapped_authors"], {})

    def test_record_shows_diff_and_allows_first_member_before_team_target(self):
        self.run_git("-c", "user.name=Bedirhan Ceylan", "-c",
            "user.email=bedirhancceylan@example.test", "commit", "--amend", "--reset-author", "--no-edit", "-q")
        result = self.record()
        self.assertEqual(result.returncode, 0, result.stderr)
        report = json.loads((self.repo / ".git" / "inout-push-approval.json").read_text())
        self.assertEqual({member["username"]: member["count"] for member in report["team"]},
            {"huseyinvk": 0, "damland7": 0, "berreozcanak": 0, "bedirhancceylan": 1})
        self.assertEqual(report["ref_freshness"]["origin"], "freshly fetched")
        self.assertIn("diff --git a/file b/file\n", result.stdout)
        self.assertIn("eventual", result.stdout.lower())
        self.assertIn("8", result.stdout)
        self.assertIn("max-min <= 1", result.stdout)

    def test_fresh_record_fetches_all_origin_branches_with_narrowed_refspec(self):
        self.run_git("switch", "-qc", "feature/damla", "origin/main")
        self.commit_as("Damla Kandemir", "damland7@example.test", "damla", "build feed")
        self.run_git("push", "-q", "origin", "feature/damla")
        self.run_git("switch", "-q", "feature/test")
        self.run_git("branch", "-D", "feature/damla")
        self.run_git("update-ref", "-d", "refs/remotes/origin/feature/damla")
        self.run_git("config", "remote.origin.fetch", "+refs/heads/main:refs/remotes/origin/main")
        result = self.record()
        self.assertEqual(result.returncode, 0, result.stderr)
        approved = json.loads((self.repo / ".git" / "inout-push-approval.json").read_text())
        counts = {member["username"]: member["count"] for member in approved["team"]}
        self.assertEqual(counts["damland7"], 1)
        self.assertEqual(approved["count"], 1)

    def test_unreviewed_push_is_blocked(self):
        result = self.run_script("--check-hook")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("No push review", result.stderr)

    def test_reviewed_exact_push_passes_and_consumes_approval(self):
        path, report = self.approve_fixture()
        result = self.run_hook(report)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(path.exists())

    def test_new_commit_invalidates_review(self):
        _, report = self.approve_fixture()
        (self.repo / "file").write_text("next")
        self.run_git("commit", "-qam", "next change")
        result = self.run_hook(report)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("changed", result.stderr)

    def test_remote_change_blocks_push(self):
        _, report = self.approve_fixture()
        result = self.run_hook(report, data=self.update_line(report, "a" * 40))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Remote branch changed", result.stderr)

    def test_dirty_worktree_blocks_push(self):
        _, report = self.approve_fixture()
        (self.repo / "file").write_text("uncommitted")
        result = self.run_hook(report)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Working tree", result.stderr)

    def test_expired_review_blocks_push(self):
        path, report = self.approve_fixture()
        report["created"] = time.time() - 601
        path.write_text(json.dumps(report))
        result = self.run_hook(report)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("expired", result.stderr)

    def test_failed_fetch_never_creates_approval(self):
        self.run_git("remote", "set-url", "origin", str(self.root / "missing.git"))
        result = self.run_script("--record")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.repo / ".git" / "inout-push-approval.json").exists())

    def test_another_remote_same_url_cannot_reuse_approval(self):
        path, report = self.approve_fixture()
        result = self.run_hook(report, remote="another")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("destination", result.stderr)
        self.assertTrue(path.exists())

    def test_explicit_url_destination_cannot_reuse_approval(self):
        _, report = self.approve_fixture()
        result = self.run_hook(report, remote=str(self.origin))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("destination", result.stderr)

    def test_another_hook_url_cannot_reuse_approval(self):
        _, report = self.approve_fixture()
        result = self.run_hook(report, url=self.root / "another.git")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("destination", result.stderr)

    def test_changed_configured_push_url_invalidates_approval(self):
        _, report = self.approve_fixture()
        self.run_git("remote", "set-url", "--push", "origin", str(self.root / "another.git"))
        result = self.run_hook(report)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("destination", result.stderr)

    def test_multiple_origin_push_urls_are_not_approved(self):
        self.run_git("remote", "set-url", "--push", "origin", str(self.origin))
        self.run_git("remote", "set-url", "--add", "--push", "origin",
            str(self.root / "another.git"))
        result = self.record()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("one push URL", result.stderr)
        self.assertFalse((self.repo / ".git" / "inout-push-approval.json").exists())

    def test_shell_hook_forwards_destination_arguments(self):
        scripts = self.repo / "scripts"
        scripts.mkdir()
        (scripts / "push_review.py").write_bytes(SCRIPT.read_bytes())
        self.run_git("add", "scripts/push_review.py")
        self.run_git("commit", "-qm", "add push review fixture")
        _, report = self.approve_fixture()
        result = subprocess.run(["sh", str(HOOK), "origin", str(self.origin)],
            cwd=self.repo, input=self.update_line(report), text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_missing_hook_destination_is_blocked(self):
        _, report = self.approve_fixture()
        result = self.run_script("--check-hook", data=self.update_line(report))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("destination", result.stderr)

if __name__ == "__main__":
    unittest.main()
