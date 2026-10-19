#!/usr/bin/env python3
"""Exercise release automation in a temporary repository with fake Apple tools."""

import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parent.parent

MOCK_TOOL = r'''#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys

tool = Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ["RELEASE_TEST_TRACE"], "a") as trace:
    trace.write(json.dumps([tool, *args]) + "\n")
if tool == "hdiutil":
    Path(args[-1]).write_bytes(b"test DMG")
elif tool == "codesign":
    if os.environ.get("FAIL_CODESIGN") == "1":
        sys.exit(1)
    if "-d" in args:
        print("CodeDirectory flags=0x10000(runtime)")
        print("TeamIdentifier=TESTTEAM")
elif tool == "ditto":
    Path(args[-1]).write_bytes(b"test ZIP")
elif tool == "xcrun":
    if args[:2] == ["xccov", "view"]:
        print(os.environ["COVERAGE_REPORT"])
    if args[:4] == ["xcresulttool", "get", "test-results", "summary"]:
        if "--format" in args:
            sys.exit(2)
        print(os.environ.get("TEST_SUMMARY", '{"passedTests":1,"failedTests":0,"expectedFailures":0}'))
    if args[:2] == ["notarytool", "submit"]:
        status = os.environ.get("NOTARY_STATUS", "Accepted")
        print(json.dumps({"id": "test-submission", "status": status}))
        sys.exit(int(os.environ.get("NOTARY_EXIT", "0")))
    if args[:2] == ["notarytool", "log"]:
        Path(args[3]).write_text('{"issues": ["test rejection"]}')
'''


class ReleaseAutomationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="easykey-release-test-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.scripts = self.root / "Scripts"
        self.scripts.mkdir()
        for name in ("create-dmg.sh", "notarize.sh", "staple.sh", "release-env.sh", "verify-release.sh", "check-shard-tests.sh", "check-coverage.sh"):
            shutil.copy2(ROOT / "Scripts" / name, self.scripts / name)
        shutil.copy2(ROOT / "Makefile", self.root / "Makefile")
        self.app = self.root / "build/export/EasyKey.app"
        contents = self.app / "Contents"
        contents.mkdir(parents=True)
        (contents / "Info.plist").write_bytes(plistlib.dumps({"CFBundleShortVersionString": "1.2.3"}))
        (contents / "MacOS").mkdir()
        (contents / "MacOS/EasyKey").touch()
        (contents / "Resources").mkdir()
        for name in ("LICENSE", "NOTICE", "THIRD_PARTY_NOTICES.md"):
            (contents / "Resources" / name).touch()
        self.dmg = self.root / "build/EasyKey-1.2.3-universal.dmg"
        self.trace = self.root / "trace.jsonl"
        binary_directory = self.root / "bin"
        binary_directory.mkdir()
        for name in ("hdiutil", "codesign", "ditto", "xcrun", "spctl"):
            path = binary_directory / name
            path.write_text(MOCK_TOOL)
            path.chmod(0o755)
        self.env = {
            "PATH": f"{binary_directory}:{Path(sys.executable).parent}:{os.environ['PATH']}",
            "RELEASE_TEST_TRACE": str(self.trace),
            "DEVELOPER_ID_APPLICATION": "Developer ID Application: Test (TESTTEAM)",
            "NOTARY_KEYCHAIN_PROFILE": "test-profile",
        }
        for name in ("verify-arch.sh", "verify-macos-compatibility.sh", "check-release-config.sh"):
            self.stub(name, 'exit 0\n')

    def stub(self, name, body):
        path = self.scripts / name
        path.write_text("#!/bin/zsh\nset -euo pipefail\n" + body)
        path.chmod(0o755)

    def run_script(self, name, *args, success=True, **environment):
        result = subprocess.run(
            [str(self.scripts / name), *map(str, args)], cwd=self.root,
            env={**self.env, **environment}, capture_output=True, text=True,
        )
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def calls(self):
        return [json.loads(line) for line in self.trace.read_text().splitlines()] if self.trace.exists() else []

    def test_signed_dmg_is_signed_and_verified_with_timestamp(self):
        self.run_script("create-dmg.sh", self.app, SIGN_DMG="1")
        calls = self.calls()
        self.assertEqual([call[0] for call in calls], ["hdiutil", "codesign", "codesign"])
        self.assertIn("--timestamp", calls[1])
        self.assertIn(self.env["DEVELOPER_ID_APPLICATION"], calls[1])
        self.assertIn("--verify", calls[2])

    def test_local_dmg_does_not_require_signing(self):
        self.env.pop("DEVELOPER_ID_APPLICATION")
        self.run_script("create-dmg.sh", self.app)
        self.assertEqual([call[0] for call in self.calls()], ["hdiutil"])

    def test_missing_identity_fails_before_creating_dmg(self):
        self.env.pop("DEVELOPER_ID_APPLICATION")
        self.run_script("create-dmg.sh", self.app, success=False, SIGN_DMG="1")
        self.assertFalse(self.dmg.exists())

    def test_signing_failure_is_propagated(self):
        self.run_script("create-dmg.sh", self.app, success=False, SIGN_DMG="1", FAIL_CODESIGN="1")

    def test_signing_loads_local_environment(self):
        self.env.pop("DEVELOPER_ID_APPLICATION")
        (self.root / ".env.local").write_text("DEVELOPER_ID_APPLICATION=Local test identity\n")
        self.run_script("create-dmg.sh", self.app, SIGN_DMG="1")
        self.assertIn("Local test identity", self.calls()[1])

    def test_notarization_accepted(self):
        self.dmg.touch()
        self.run_script("notarize.sh", self.dmg)

    def test_notarization_invalid_status_fails_even_with_zero_exit(self):
        self.dmg.touch()
        self.run_script("notarize.sh", self.dmg, success=False, NOTARY_STATUS="Invalid")
        self.assertTrue((self.root / "build/notarization" / f"{self.dmg.name}.log.json").exists())

    def test_notarization_nonzero_exit_fails_even_with_accepted_status(self):
        self.dmg.touch()
        self.run_script("notarize.sh", self.dmg, success=False, NOTARY_EXIT="1")

    def test_notarization_loads_local_credentials(self):
        self.env.pop("NOTARY_KEYCHAIN_PROFILE")
        (self.root / ".env.local").write_text("NOTARY_KEYCHAIN_PROFILE=local-test-profile\n")
        self.dmg.touch()
        self.run_script("notarize.sh", self.dmg)
        self.assertIn("local-test-profile", self.calls()[0])

    def test_shard_summary_accepts_executed_tests(self):
        self.run_script("check-shard-tests.sh", self.app)

    def test_shard_summary_rejects_only_skipped_tests(self):
        self.run_script(
            "check-shard-tests.sh", self.app, success=False,
            TEST_SUMMARY='{"passedTests":0,"failedTests":0,"expectedFailures":0,"skippedTests":10}',
        )

    def test_shard_summary_rejects_unknown_schema(self):
        self.run_script("check-shard-tests.sh", self.app, success=False, TEST_SUMMARY='{}')

    def coverage_report(self, product_covered=95):
        targets = [
            {"name": name, "coveredLines": product_covered, "executableLines": 100}
            for name in ("EasyKey.app", "EasyEngineCore.framework", "EasyKeyKit.framework")
        ]
        targets.append({"name": "EasyKeyTests.xctest", "coveredLines": 10000, "executableLines": 10000})
        return {"targets": targets}

    def test_product_coverage_passes(self):
        self.run_script("check-coverage.sh", self.app, COVERAGE_REPORT=json.dumps(self.coverage_report()))

    def test_test_coverage_cannot_inflate_product_coverage(self):
        self.run_script("check-coverage.sh", self.app, success=False, COVERAGE_REPORT=json.dumps(self.coverage_report(80)))

    def test_missing_product_coverage_is_rejected(self):
        report = self.coverage_report()
        report["targets"].pop(0)
        self.run_script("check-coverage.sh", self.app, success=False, COVERAGE_REPORT=json.dumps(report))

    def test_release_verification_checks_dmg_signature(self):
        self.dmg.touch()
        self.run_script("verify-release.sh", self.app, self.dmg)
        self.assertIn(["codesign", "--verify", "--strict", "--verbose=2", str(self.dmg)], self.calls())

    def test_parallel_make_orders_archive_export_signing_and_notarization(self):
        order = self.root / "order"
        self.stub("archive.sh", f'print archive >> "{order}"\nmkdir -p build/archives\ntouch build/archives/ready\n')
        self.stub("export.sh", f'[[ -f build/archives/ready ]]\nprint export >> "{order}"\n')
        result = subprocess.run(["make", "-j4", "dmg"], cwd=self.root, env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(order.read_text().splitlines(), ["archive", "export"])
        calls = self.calls()
        sign_index = next(i for i, call in enumerate(calls) if call[0] == "codesign" and "--sign" in call)
        submit_index = next(
            i for i, call in enumerate(calls)
            if call[:3] == ["xcrun", "notarytool", "submit"] and Path(call[3]).resolve() == self.dmg.resolve()
        )
        self.assertLess(sign_index, submit_index)


class AppcastTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="easykey-appcast-test-")
        self.addCleanup(self.temporary.cleanup)
        self.path = Path(self.temporary.name) / "appcast.xml"

    def generate(self, *, success=True, build="14", signature="test-signature", url=None):
        result = subprocess.run([
            sys.executable, str(ROOT / "Scripts/generate-appcast.py"), str(self.path),
            "0.0.15", build, url or "https://example.com/EasyKey-0.0.15.dmg", "100", signature,
            "14.0", "Mon, 19 Oct 2026 00:00:00 +0000",
        ], capture_output=True, text=True)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)

    def test_duplicate_release_is_noop(self):
        self.generate()
        original = self.path.read_bytes()
        self.generate()
        self.assertEqual(self.path.read_bytes(), original)

    def test_conflicting_duplicate_is_rejected(self):
        self.generate()
        original = self.path.read_bytes()
        self.generate(success=False, signature="different-signature")
        self.assertEqual(self.path.read_bytes(), original)

    def test_duplicate_url_with_different_build_is_rejected(self):
        self.generate()
        self.generate(success=False, build="15")

    def test_non_https_url_is_rejected(self):
        self.generate(success=False, url="http://example.com/update.dmg")

    def test_invalid_existing_xml_is_not_overwritten(self):
        self.path.write_text("<invalid")
        self.generate(success=False)
        self.assertEqual(self.path.read_text(), "<invalid")


class DraftReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="easykey-draft-test-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        workflow = subprocess.run(
            ["ruby", "-r", "yaml", "-r", "json", "-e", "puts JSON.generate(YAML.load_file(ARGV[0]))",
             str(ROOT / ".github/workflows/release.yml")],
            check=True, capture_output=True, text=True,
        )
        steps = json.loads(workflow.stdout)["jobs"]["release"]["steps"]
        self.script = next(step["run"] for step in steps if step["name"] == "Create or update draft release")
        self.assets = self.root / "build/release"
        self.assets.mkdir(parents=True)
        for target in ("universal", "arm64", "amd64"):
            (self.assets / f"EasyKey-1.2.3-{target}.dmg").write_bytes(b"test image")
        binary_directory = self.root / "bin"
        binary_directory.mkdir()
        gh = binary_directory / "gh"
        gh.write_text("""#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
args=sys.argv[1:]
with open('gh-calls.jsonl','a') as trace:
    trace.write(json.dumps(args)+'\\n')
if args[:2] == ['release','view']:
    state=os.environ['RELEASE_STATE']
    if state == 'missing':
        sys.exit(1)
    print(json.dumps({'isDraft':state == 'draft'}))
""")
        gh.chmod(0o755)
        self.env = {**os.environ, "PATH": f"{binary_directory}:{os.environ['PATH']}", "TAG_NAME": "v1.2.3"}

    def run_release(self, state, *, success=True):
        result = subprocess.run(
            ["bash", "--noprofile", "--norc", "-e", "-o", "pipefail", "-c", self.script],
            cwd=self.root, env={**self.env, "RELEASE_STATE": state}, capture_output=True, text=True,
        )
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        trace = self.root / "gh-calls.jsonl"
        return [json.loads(line) for line in trace.read_text().splitlines()] if trace.exists() else []

    def test_new_draft_is_created_with_verified_tag(self):
        calls = self.run_release("missing")
        self.assertEqual(calls[-1][:2], ["release", "create"])
        self.assertIn("--verify-tag", calls[-1])
        self.assertIn("--draft", calls[-1])

    def test_existing_draft_assets_can_be_retried(self):
        calls = self.run_release("draft")
        self.assertEqual(calls[-1][:2], ["release", "upload"])
        self.assertIn("--clobber", calls[-1])

    def test_published_release_is_not_modified(self):
        calls = self.run_release("published", success=False)
        self.assertEqual(len(calls), 1)

    def test_missing_architecture_prevents_release(self):
        (self.assets / "EasyKey-1.2.3-amd64.dmg").unlink()
        self.assertEqual(self.run_release("missing", success=False), [])


class CIConfigGuardTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="easykey-config-test-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        (self.root / "Scripts").mkdir()
        shutil.copy2(ROOT / "Scripts/check-ci-config.py", self.root / "Scripts/check-ci-config.py")
        shutil.copytree(ROOT / "EasyKeyTests", self.root / "EasyKeyTests")
        shutil.copytree(ROOT / "EasyKeyUITests", self.root / "EasyKeyUITests")
        (self.root / ".github/workflows").mkdir(parents=True)
        self.workflow = self.root / ".github/workflows/ci.yml"
        shutil.copy2(ROOT / ".github/workflows/ci.yml", self.workflow)

    def check(self, *, success=True):
        result = subprocess.run(
            [sys.executable, str(self.root / "Scripts/check-ci-config.py")], capture_output=True, text=True,
        )
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)

    def test_current_workflow_covers_every_suite(self):
        self.check()

    def test_missing_suite_assignment_is_rejected(self):
        self.workflow.write_text(self.workflow.read_text().replace("-only-testing:EasyKeyTests/MacroSamplesTests", ""))
        self.check(success=False)

    def test_stale_suite_selection_is_rejected(self):
        self.workflow.write_text(self.workflow.read_text() + "\n# -only-testing:EasyKeyTests/DeletedTests\n")
        self.check(success=False)


if __name__ == "__main__":
    unittest.main(verbosity=2)
