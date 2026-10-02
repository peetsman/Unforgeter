#!/usr/bin/env python3
"""Preview locally; use --apply to create only missing Unforgeter GitHub resources.

Standard library only. Preview never reads credentials, contacts GitHub, or writes
files. Apply preserves existing remote content, including closed issues.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import quote, urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener

REPOSITORY = "peetsman/Unforgeter"
API_ORIGIN = "https://api.github.com"
ROOT = Path(__file__).resolve().parents[1]
BACKLOG_PATH = ROOT / "docs" / "backlog.json"
MAP_PATH = ROOT / "docs" / "github-backlog-map.json"
MARKER_PATTERN = re.compile(r"<!--\s*unforgeter-backlog:(M[0-4]-\d{2})\s*-->")
LABEL_COLORS = {
    "feature": "a2eeef", "bug": "d73a4a", "setup": "c5def5",
    "architecture": "5319e7", "UI/UX": "d4c5f9", "location": "0075ca",
    "geofencing": "0052cc", "notifications": "bfd4f2", "data": "bfdadc",
    "testing": "0e8a16", "documentation": "0075ca", "privacy": "e4e669",
    "MVP": "006b75", "future": "ededed", "P0-critical": "b60205",
    "P1-high": "d93f0b", "P2-medium": "fbca04", "P3-low": "c2e0c6",
}


class SyncError(Exception):
    """Safe user-facing error that must not contain response bodies or tokens."""


class NoRedirects(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        # Never forward Authorization to a redirected destination.
        return None


def get_token(repo_root: Path = ROOT) -> str:
    """Read a token without printing it, putting it in arguments, or saving it."""
    token = os.environ.get("GITHUB_TOKEN", "").strip()
    if token:
        return token
    environment = os.environ.copy()
    environment.update(GIT_TERMINAL_PROMPT="0", GCM_INTERACTIVE="never")
    try:
        result = subprocess.run(
            ["git", "-c", "credential.interactive=false", "credential", "fill"],
            input="protocol=https\nhost=github.com\n\n",
            text=True, capture_output=True, cwd=repo_root, env=environment,
            timeout=30, check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        raise SyncError(
            "Git credentials could not be read without prompting. Configure a "
            "GitHub credential or set GITHUB_TOKEN, then run --apply again."
        ) from None
    if result.returncode == 0:
        for line in result.stdout.splitlines():
            key, separator, value = line.partition("=")
            if separator and key == "password" and value:
                return value
    # Git stdout/stderr can contain credentials; never include either in errors.
    raise SyncError(
        "No noninteractive GitHub credential was available. Configure Git "
        "authentication or set GITHUB_TOKEN, then run --apply again."
    )


class GitHubClient:
    """Small reusable client; all requests stay in this repository's API scope."""

    def __init__(self, token: str):
        # Invalid header values can appear verbatim in urllib exceptions. Reject
        # malformed credentials before constructing any request or header.
        if not isinstance(token, str) or not token or any(
            ord(character) < 33 or ord(character) > 126 for character in token
        ):
            raise SyncError("GitHub credential has an invalid format; refresh the credential.")
        self._token = token
        self._opener = build_opener(NoRedirects())
        self._last_write: float | None = None

    def _url(self, path: str) -> str:
        url = path if path.startswith("https://") else API_ORIGIN + path
        parts = urlsplit(url)
        prefix = f"/repos/{REPOSITORY}"
        if (
            parts.scheme != "https" or parts.netloc != "api.github.com"
            or parts.username or parts.password or parts.fragment
            or not (parts.path == prefix or parts.path.startswith(prefix + "/"))
        ):
            raise SyncError("Refusing an API URL outside the configured repository.")
        return url

    def request(
        self, method: str, path: str, payload: dict[str, Any] | None = None,
    ) -> tuple[Any, Any]:
        method = method.upper()
        if method not in {"GET", "POST", "PATCH", "PUT", "DELETE"}:
            raise SyncError("Unsupported HTTP method.")
        url = self._url(path)
        if method != "GET":
            if self._last_write is not None:
                time.sleep(max(0.0, 1.0 - (time.monotonic() - self._last_write)))
            self._last_write = time.monotonic()
        encoded = None if payload is None else json.dumps(payload).encode("utf-8")
        request = Request(
            url, data=encoded, method=method,
            headers={
                "Accept": "application/vnd.github+json",
                "Authorization": f"Bearer {self._token}",
                "X-GitHub-Api-Version": "2022-11-28",
                "User-Agent": "Unforgeter-backlog-sync",
                "Content-Type": "application/json",
            },
        )
        try:
            with self._opener.open(request, timeout=45) as response:
                content = response.read()
                headers = response.headers
        except HTTPError as error:
            status = error.code
            hint = {
                301: "Repository redirected; verify its canonical owner/name.",
                302: "Repository redirected; verify its canonical owner/name.",
                307: "Repository redirected; verify its canonical owner/name.",
                308: "Repository redirected; verify its canonical owner/name.",
                401: "Authentication failed; refresh the GitHub credential.",
                403: "Check repository permissions and API rate limits; wait before retrying.",
                404: "Check repository access, credential permissions, and the requested resource.",
                422: "GitHub rejected the resource; check for a concurrent create or invalid backlog data.",
                429: "GitHub rate-limited the request; wait before retrying.",
            }.get(status, "Check GitHub availability and retry later.")
            # Deliberately omit server response text, headers, URL queries, and bodies.
            raise SyncError(
                f"GitHub {method} returned HTTP {status}. {hint} "
                "Existing resources will be rechecked on the next run."
            ) from None
        except (URLError, TimeoutError, OSError):
            raise SyncError(
                f"GitHub {method} could not complete. Check the network/proxy and "
                "retry. A write may have reached GitHub; rerunning rechecks existing resources."
            ) from None
        if not content:
            return None, headers
        try:
            return json.loads(content), headers
        except (json.JSONDecodeError, UnicodeDecodeError):
            raise SyncError(
                "GitHub returned an unreadable response. Rerun to recheck existing resources."
            ) from None

    def paginate(self, path: str) -> list[dict[str, Any]]:
        items: list[dict[str, Any]] = []
        visited: set[str] = set()
        next_url: str | None = path
        while next_url:
            canonical = self._url(next_url)
            if canonical in visited:
                raise SyncError("GitHub pagination repeated a page; no partial list will be used.")
            visited.add(canonical)
            page, headers = self.request("GET", canonical)
            if not isinstance(page, list) or any(not isinstance(x, dict) for x in page):
                raise SyncError("GitHub returned an unexpected paginated response.")
            items.extend(page)
            next_url = None
            for link in headers.get("Link", "").split(","):
                target = re.search(r"<([^>]+)>", link)
                relation = re.search(r'\brel="([^"]+)"', link)
                if target and relation and "next" in relation.group(1).split():
                    next_url = target.group(1)
                    break
        return items


def load_backlog(path: Path = BACKLOG_PATH) -> dict[str, Any]:
    def require(condition: Any) -> None:
        if not condition:
            raise ValueError("Invalid backlog structure")

    try:
        data = json.loads(path.read_text(encoding="utf-8-sig"))
    except (OSError, json.JSONDecodeError, UnicodeDecodeError):
        raise SyncError("Cannot read docs/backlog.json as UTF-8 JSON.") from None
    try:
        require(isinstance(data, dict))
        require(data["schemaVersion"] == 1)
        require(data["repository"] == f"https://github.com/{REPOSITORY}")
        labels = data["labels"]
        milestones = data["milestones"]
        issues = data["issues"]
        require(isinstance(labels, list) and all(isinstance(x, str) and x for x in labels))
        require(len({x.casefold() for x in labels}) == len(labels))
        require(isinstance(milestones, list) and len(milestones) == 5)
        milestone_ids = {m["id"] for m in milestones}
        require(milestone_ids == {"M0", "M1", "M2", "M3", "M4"})
        require(all(isinstance(m["title"], str) and m["title"] for m in milestones))
        require(all(isinstance(m["objective"], str) for m in milestones))
        require(len({m["title"] for m in milestones}) == len(milestones))
        require(isinstance(issues, list) and len(issues) == 46)
        local_ids = {i["localId"] for i in issues}
        require(len(local_ids) == 46)
        require({i["sourceNumber"] for i in issues} == set(range(1, 47)))
        require(len({i["title"] for i in issues}) == 46)
        for issue in issues:
            require(re.fullmatch(r"M[0-4]-\d{2}", issue["localId"]))
            require(issue["localId"] == f'{issue["milestone"]}-{issue["sourceNumber"]:02d}')
            require(issue["milestone"] in milestone_ids)
            require(isinstance(issue["title"], str) and 0 < len(issue["title"]) <= 256)
            require(isinstance(issue["body"], str) and issue["body"].strip())
            require(len(issue["body"]) < 65000)
            require(isinstance(issue["labels"], list))
            require(set(issue["labels"]).issubset(labels))
            require(set(issue["dependsOn"]).issubset(local_ids))
    except (KeyError, TypeError, ValueError):
        raise SyncError(
            "Backlog validation failed. Expected five milestones, 46 uniquely "
            "identified items, known labels/dependencies, and nonempty titles/bodies."
        ) from None
    return data


def marker(local_id: str) -> str:
    return f"<!-- unforgeter-backlog:{local_id} -->"


def issue_number(issue: dict[str, Any]) -> int:
    if not isinstance(issue, dict):
        raise SyncError("GitHub returned an unexpected resource response.")
    value = issue.get("number")
    if not isinstance(value, int) or isinstance(value, bool) or value <= 0:
        raise SyncError("GitHub returned a resource without a valid number.")
    return value


def issue_url(number: int) -> str:
    return f"https://github.com/{REPOSITORY}/issues/{number}"


def find_existing(
    planned: list[dict[str, Any]], remote: list[dict[str, Any]],
) -> dict[str, dict[str, Any]]:
    """Prefer a stable marker; exact-title fallback supports older manual issues."""
    remote = [x for x in remote if "pull_request" not in x]
    found: dict[str, dict[str, Any]] = {}
    claimed: set[int] = set()
    for item in planned:
        local_id = item["localId"]
        marked = [x for x in remote if local_id in MARKER_PATTERN.findall(x.get("body") or "")]
        matches = marked or [
            x for x in remote
            if x.get("title") == item["title"]
            and not MARKER_PATTERN.search(x.get("body") or "")
        ]
        if len(matches) > 1:
            raise SyncError(
                f"Multiple existing issues match {local_id}. Resolve the ambiguity "
                "before applying; no existing issue will be overwritten."
            )
        if matches:
            number = issue_number(matches[0])
            if number in claimed:
                raise SyncError(f"One existing issue matches multiple local IDs, including {local_id}.")
            claimed.add(number)
            found[local_id] = matches[0]
    return found


def record_issue(issue: dict[str, Any]) -> dict[str, Any]:
    number = issue_number(issue)
    return {
        "number": number, "url": issue_url(number),
        "title": issue.get("title", ""), "state": issue.get("state", "unknown"),
    }


def save_map(
    mapping: dict[str, Any], counts: dict[str, int], complete: bool,
    path: Path = MAP_PATH,
) -> None:
    document = {
        "schemaVersion": 1,
        "repository": f"https://github.com/{REPOSITORY}",
        "updatedAt": dt.datetime.now(dt.timezone.utc).isoformat(),
        "syncStatus": "complete" if complete else "partial",
        "note": "Actual GitHub numbers mapped to stable local IDs; existing content was not overwritten.",
        "counts": counts, "issues": dict(sorted(mapping.items())),
    }
    temporary: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", newline="\n", suffix=".tmp",
            prefix="github-backlog-map-", dir=path.parent, delete=False,
        ) as stream:
            temporary = Path(stream.name)
            json.dump(document, stream, indent=2, ensure_ascii=False)
            stream.write("\n")
        os.replace(temporary, path)
    except OSError:
        raise SyncError(
            "Could not save docs/github-backlog-map.json. Remote changes may exist; "
            "rerun to reconstruct the map without overwriting those resources."
        ) from None
    finally:
        if temporary is not None and temporary.exists():
            try:
                temporary.unlink()
            except OSError:
                pass


def preview(data: dict[str, Any]) -> None:
    print(f"LOCAL PREVIEW — {REPOSITORY}")
    print("No credentials read, network calls made, or files written.")
    print(
        f"Plan: {len(data['labels'])} labels, {len(data['milestones'])} milestones, "
        f"{len(data['issues'])} issues. Apply will create only missing resources."
    )
    for milestone in data["milestones"]:
        print(f"\n{milestone['title']}: {milestone['objective']}")
        for item in data["issues"]:
            if item["milestone"] == milestone["id"]:
                print(f"  {item['localId']}  {item['title']}")
    print("\nUse --apply to inspect GitHub and create missing resources.")
    print("Existing matching content and manual edits will be preserved.")


def apply(data: dict[str, Any], client: GitHubClient) -> dict[str, int]:
    base = f"/repos/{REPOSITORY}"
    # Complete every paginated read and ambiguity check before the first write.
    labels = client.paginate(f"{base}/labels?per_page=100")
    milestones = client.paginate(f"{base}/milestones?state=all&per_page=100")
    issues = client.paginate(f"{base}/issues?state=all&per_page=100")
    label_names = {x["name"].casefold(): x["name"] for x in labels}
    milestone_numbers: dict[str, int] = {}
    for planned in data["milestones"]:
        matches = [x for x in milestones if x.get("title") == planned["title"]]
        if len(matches) > 1:
            raise SyncError(f"Multiple milestones match {planned['id']}; resolve the ambiguity first.")
        if matches:
            milestone_numbers[planned["id"]] = issue_number(matches[0])
    matched = find_existing(data["issues"], issues)
    mapping = {local_id: record_issue(issue) for local_id, issue in matched.items()}
    counts = {
        "labelsCreated": 0, "milestonesCreated": 0, "issuesCreated": 0,
        "issuesReused": len(matched),
    }
    complete = False
    try:
        for name in data["labels"]:
            if name.casefold() in label_names:
                continue
            client.request("POST", f"{base}/labels", {
                "name": name, "color": LABEL_COLORS.get(name, "ededed"),
                "description": f"Unforgeter planning: {name}",
            })
            label_names[name.casefold()] = name
            counts["labelsCreated"] += 1
            print(f"Created label: https://github.com/{REPOSITORY}/labels/{quote(name, safe='')}", flush=True)
        for milestone in data["milestones"]:
            if milestone["id"] in milestone_numbers:
                continue
            created, _ = client.request("POST", f"{base}/milestones", {
                "title": milestone["title"], "description": milestone["objective"],
            })
            number = issue_number(created)
            milestone_numbers[milestone["id"]] = number
            counts["milestonesCreated"] += 1
            print(f"Created milestone: https://github.com/{REPOSITORY}/milestone/{number}", flush=True)
        for item in data["issues"]:
            local_id = item["localId"]
            if local_id in matched:
                print(f"Reused {local_id}: {mapping[local_id]['url']}", flush=True)
                continue
            body = item["body"].rstrip() + "\n\n" + marker(local_id)
            created, _ = client.request("POST", f"{base}/issues", {
                "title": item["title"], "body": body,
                "labels": [label_names[x.casefold()] for x in item["labels"]],
                "milestone": milestone_numbers[item["milestone"]],
            })
            mapping[local_id] = record_issue(created)
            counts["issuesCreated"] += 1
            print(f"Created {local_id}: {mapping[local_id]['url']}", flush=True)
        complete = True
        return counts
    finally:
        # Preserve successful creations and existing matches even after an error
        # or Ctrl+C. A failed initial read never replaces an earlier mapping file.
        save_map(mapping, counts, complete)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--apply", action="store_true",
        help="contact GitHub and create missing resources; default is a local-only preview",
    )
    args = parser.parse_args(argv)
    try:
        data = load_backlog()
        if not args.apply:
            preview(data)
            return 0
        counts = apply(data, GitHubClient(get_token()))
        print(
            "\nComplete: "
            f"{counts['labelsCreated']} labels, {counts['milestonesCreated']} milestones, "
            f"{counts['issuesCreated']} issues created; {counts['issuesReused']} issues reused."
        )
        print("Issue mapping saved to docs/github-backlog-map.json.")
        return 0
    except SyncError as error:
        print(f"Error: {error}", file=sys.stderr)
        if args.apply:
            print(
                "Any completed writes are retained. When sync reached its write "
                "phase, it attempted to save partial issue mappings. "
                "Rerun safely after resolving the problem.",
                file=sys.stderr,
            )
        return 1
    except KeyboardInterrupt:
        print("\nInterrupted. Rerun to recheck and resume missing resources.", file=sys.stderr)
        return 130


if __name__ == "__main__":
    raise SystemExit(main())
