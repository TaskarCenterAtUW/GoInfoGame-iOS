#!/usr/bin/env python3
"""Build a human-readable test report (Markdown + HTML) from CI test output.

Inputs:
  --junit     Path to a JUnit XML file (produced by xcbeautify).
  --xcresult  Optional .xcresult bundle - used only for code coverage.
  --out-dir   Directory to write test-report.md / test-report.html into.

Everything is stdlib-only so it runs on any macOS runner with python3.
Metadata is read from GitHub Actions env vars when present.
"""

from __future__ import annotations

import argparse
import html
import json
import os
import subprocess
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from datetime import datetime, timezone


@dataclass
class Case:
    suite: str
    name: str
    time: float
    status: str  # "passed" | "failed" | "skipped"
    message: str = ""
    detail: str = ""


@dataclass
class Suite:
    name: str
    cases: list[Case] = field(default_factory=list)

    @property
    def time(self) -> float:
        return sum(c.time for c in self.cases)

    def count(self, status: str) -> int:
        return sum(1 for c in self.cases if c.status == status)


def parse_junit(path: str) -> list[Suite]:
    if not path or not os.path.isfile(path):
        return []
    root = ET.parse(path).getroot()
    suite_nodes = root.iter("testsuite")
    suites: dict[str, Suite] = {}
    for sn in suite_nodes:
        sname = sn.get("name") or "Tests"
        suite = suites.setdefault(sname, Suite(sname))
        for tc in sn.findall("testcase"):
            cname = tc.get("name") or "?"
            ctime = float(tc.get("time") or 0.0)
            failure = tc.find("failure")
            error = tc.find("error")
            skipped = tc.find("skipped")
            if failure is not None or error is not None:
                node = failure if failure is not None else error
                suite.cases.append(Case(
                    sname, cname, ctime, "failed",
                    message=(node.get("message") or "").strip(),
                    detail=(node.text or "").strip(),
                ))
            elif skipped is not None:
                suite.cases.append(Case(sname, cname, ctime, "skipped",
                                        message=(skipped.get("message") or "").strip()))
            else:
                suite.cases.append(Case(sname, cname, ctime, "passed"))
    return sorted(suites.values(), key=lambda s: s.name)


def coverage_from_xcresult(xcresult: str) -> dict | None:
    if not xcresult or not os.path.isdir(xcresult):
        return None
    try:
        out = subprocess.run(
            ["xcrun", "xccov", "view", "--report", "--json", xcresult],
            capture_output=True, text=True, check=True,
        ).stdout
        return json.loads(out)
    except (subprocess.CalledProcessError, json.JSONDecodeError, FileNotFoundError):
        return None


def fmt_pct(x: float) -> str:
    return f"{x * 100:.1f}%"


def build_markdown(suites: list[Suite], cov: dict | None, meta: dict) -> str:
    total = sum(len(s.cases) for s in suites)
    passed = sum(s.count("passed") for s in suites)
    failed = sum(s.count("failed") for s in suites)
    skipped = sum(s.count("skipped") for s in suites)
    duration = sum(s.time for s in suites)
    overall = "✅ PASSED" if failed == 0 and total > 0 else ("❌ FAILED" if failed else "⚠️ NO TESTS")

    L: list[str] = []
    L.append(f"# Test Report — {overall}")
    L.append("")
    if meta:
        L.append("| | |")
        L.append("|---|---|")
        for k in ("Repository", "Branch", "Commit", "Message", "Run", "Generated"):
            if meta.get(k):
                L.append(f"| **{k}** | {meta[k]} |")
        L.append("")
    L.append(f"**{passed} passed**, **{failed} failed**, **{skipped} skipped** "
             f"— {total} tests in {duration:.1f}s")
    L.append("")

    L.append("## Suites")
    L.append("")
    L.append("| Suite | Tests | ✅ | ❌ | ⏭️ | Time |")
    L.append("|---|--:|--:|--:|--:|--:|")
    for s in suites:
        L.append(f"| {s.name} | {len(s.cases)} | {s.count('passed')} | "
                 f"{s.count('failed')} | {s.count('skipped')} | {s.time:.1f}s |")
    L.append("")

    failures = [c for s in suites for c in s.cases if c.status == "failed"]
    if failures:
        L.append("## Failures")
        L.append("")
        for c in failures:
            L.append(f"### ❌ `{c.suite}.{c.name}`")
            L.append("")
            if c.message:
                L.append(f"> {c.message}")
                L.append("")
            if c.detail and c.detail != c.message:
                snippet = "\n".join(c.detail.splitlines()[:20])
                L.append("```")
                L.append(snippet)
                L.append("```")
                L.append("")

    if cov and cov.get("targets"):
        L.append("## Code coverage")
        L.append("")
        L.append("| Target | Coverage | Covered / Executable lines |")
        L.append("|---|--:|--:|")
        tgts = sorted(cov["targets"], key=lambda t: t.get("name", ""))
        tot_cov = tot_exec = 0
        for t in tgts:
            name = t.get("name", "?")
            lc = t.get("lineCoverage", 0.0)
            covd = t.get("coveredLines", 0)
            exe = t.get("executableLines", 0)
            tot_cov += covd
            tot_exec += exe
            L.append(f"| {name} | {fmt_pct(lc)} | {covd} / {exe} |")
        if tot_exec:
            L.append(f"| **Overall** | **{fmt_pct(tot_cov / tot_exec)}** | "
                     f"**{tot_cov} / {tot_exec}** |")
        L.append("")

    if not failures:
        passed_list = [c for s in suites for c in s.cases if c.status == "passed"]
        if passed_list:
            L.append("<details><summary>All passing tests</summary>")
            L.append("")
            for c in passed_list:
                L.append(f"- `{c.suite}.{c.name}` ({c.time:.2f}s)")
            L.append("")
            L.append("</details>")
            L.append("")

    return "\n".join(L)


def _inline(text: str) -> str:
    """Handle **bold**, `code`, [label](url) inside an already-escaped string."""
    import re
    esc = html.escape(text)
    esc = re.sub(r"\[([^\]]+)\]\((https?://[^)]+)\)", r'<a href="\2">\1</a>', esc)
    esc = re.sub(r"`([^`]+)`", r"<code>\1</code>", esc)
    esc = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", esc)
    return esc


def markdown_to_html(md: str, title: str) -> str:
    """Tiny, dependency-free MD->HTML good enough for the subset we emit."""
    out: list[str] = []
    in_code = in_table = in_details = False
    for raw in md.splitlines():
        line = raw
        if line.startswith("```"):
            out.append("</pre>" if in_code else "<pre>")
            in_code = not in_code
            continue
        if in_code:
            out.append(html.escape(line))
            continue
        if line.startswith("<details") or line.startswith("</details"):
            out.append(line)
            in_details = line.startswith("<details")
            continue
        if line.strip() == "":
            if in_table:
                out.append("</table>")
                in_table = False
            continue
        if line.startswith("|"):
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if set("".join(cells)) <= set("-: "):
                continue  # separator row
            if not in_table:
                out.append("<table>")
                in_table = True
            row = "".join(f"<td>{_inline(c)}</td>" for c in cells)
            out.append(f"<tr>{row}</tr>")
            continue
        if in_table:
            out.append("</table>")
            in_table = False
        if line.startswith("### "):
            out.append(f"<h3>{_inline(line[4:])}</h3>")
        elif line.startswith("## "):
            out.append(f"<h2>{_inline(line[3:])}</h2>")
        elif line.startswith("# "):
            out.append(f"<h1>{_inline(line[2:])}</h1>")
        elif line.startswith("> "):
            out.append(f"<blockquote>{_inline(line[2:])}</blockquote>")
        elif line.startswith("- "):
            out.append(f"<div class='li'>&bull; {_inline(line[2:])}</div>")
        else:
            out.append(f"<p>{_inline(line)}</p>")
    if in_table:
        out.append("</table>")
    body = "\n".join(out)
    return f"""<!doctype html><html><head><meta charset="utf-8">
<title>{html.escape(title)}</title>
<style>
 body{{font:14px -apple-system,Segoe UI,Roboto,sans-serif;max-width:900px;margin:2rem auto;padding:0 1rem;color:#1c1c1e}}
 h1{{border-bottom:2px solid #e5e5ea;padding-bottom:.3rem}}
 h2{{margin-top:2rem;border-bottom:1px solid #e5e5ea;padding-bottom:.2rem}}
 table{{border-collapse:collapse;width:100%;margin:.5rem 0}}
 th,td{{border:1px solid #d1d1d6;padding:.4rem .6rem;text-align:left}}
 th{{background:#f2f2f7}}
 pre{{background:#f6f8fa;border:1px solid #e5e5ea;border-radius:6px;padding:.6rem;overflow:auto;font:12px SFMono-Regular,Menlo,monospace}}
 blockquote{{margin:.4rem 0;padding:.2rem .8rem;border-left:3px solid #ff9500;background:#fff8ef}}
 .li{{margin:.1rem 0}}
 details{{margin:.6rem 0}}
</style></head><body>
{body}
</body></html>"""


def try_pdf(html_path: str, pdf_path: str) -> str | None:
    """Best-effort HTML->PDF using whatever converter the runner has."""
    candidates = [
        ["pandoc", html_path, "-o", pdf_path],
        ["wkhtmltopdf", "--quiet", html_path, pdf_path],
        ["weasyprint", html_path, pdf_path],
    ]
    for browser in ("google-chrome", "chromium", "chromium-browser",
                    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"):
        candidates.append([browser, "--headless", "--disable-gpu", "--no-pdf-header-footer",
                           f"--print-to-pdf={pdf_path}", f"file://{os.path.abspath(html_path)}"])
    for cmd in candidates:
        exe = cmd[0]
        found = exe if os.path.isabs(exe) and os.path.exists(exe) else _which(exe)
        if not found:
            continue
        try:
            subprocess.run(cmd, check=True, capture_output=True, timeout=120)
            if os.path.isfile(pdf_path) and os.path.getsize(pdf_path) > 0:
                return exe
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
            continue
    return None


def _which(name: str) -> str | None:
    for d in os.environ.get("PATH", "").split(os.pathsep):
        p = os.path.join(d, name)
        if os.path.isfile(p) and os.access(p, os.X_OK):
            return p
    return None


def collect_meta() -> dict:
    e = os.environ.get
    sha = e("GITHUB_SHA", "")
    server = e("GITHUB_SERVER_URL", "https://github.com")
    repo = e("GITHUB_REPOSITORY", "")
    run_id = e("GITHUB_RUN_ID", "")
    meta = {
        "Repository": repo,
        "Branch": e("GITHUB_REF_NAME", ""),
        "Commit": f"`{sha[:7]}`" if sha else "",
        "Message": (e("GIT_COMMIT_MESSAGE", "") or "").splitlines()[0] if e("GIT_COMMIT_MESSAGE") else "",
        "Run": f"[{run_id}]({server}/{repo}/actions/runs/{run_id})" if run_id and repo else "",
        "Generated": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC"),
    }
    return {k: v for k, v in meta.items() if v}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--junit", required=True)
    ap.add_argument("--xcresult", default="")
    ap.add_argument("--out-dir", default="build/report")
    args = ap.parse_args()

    os.makedirs(args.out_dir, exist_ok=True)
    suites = parse_junit(args.junit)
    if not suites:
        print(f"::warning::no test cases parsed from {args.junit}", file=sys.stderr)
    cov = coverage_from_xcresult(args.xcresult)
    meta = collect_meta()

    md = build_markdown(suites, cov, meta)
    md_path = os.path.join(args.out_dir, "test-report.md")
    html_path = os.path.join(args.out_dir, "test-report.html")
    pdf_path = os.path.join(args.out_dir, "test-report.pdf")
    with open(md_path, "w") as f:
        f.write(md)
    with open(html_path, "w") as f:
        f.write(markdown_to_html(md, "Test Report"))
    print(f"wrote {md_path}")
    print(f"wrote {html_path}")

    engine = try_pdf(html_path, pdf_path)
    if engine:
        print(f"wrote {pdf_path} (via {engine})")
    else:
        print("::notice::no HTML->PDF converter found on runner "
              "(pandoc / wkhtmltopdf / weasyprint / chrome); skipping PDF")

    # Feed the summary into the GitHub Actions run page too.
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a") as f:
            f.write(md + "\n")

    failed = sum(s.count("failed") for s in suites)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
