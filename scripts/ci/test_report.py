#!/usr/bin/env python3
"""Build a human-readable test report (Markdown + HTML + best-effort PDF) from CI output.

Usage:
  test_report.py --junit RUN[=PATH] [RUN[=PATH] ...] [--xcresult DIR] [--out-dir DIR]

Each --junit value is one "run" (e.g. the unit run, or the UI run on one device).
  * "path/to/foo.xml"          -> run label derived from the file name
  * "iPhone 16 Pro=path.xml"   -> explicit label
Globs are expanded, so `--junit "build/reports/*.xml"` also works.

--xcresult points at a .xcresult bundle used only for the code-coverage table.

Everything is stdlib-only so it runs on any macOS runner with python3.
Metadata (repo / branch / commit / run link) is read from GitHub Actions env vars.
"""

from __future__ import annotations

import argparse
import glob
import html
import json
import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from collections import OrderedDict
from dataclasses import dataclass
from datetime import datetime, timezone


@dataclass
class Case:
    run: str
    suite: str
    name: str
    time: float
    status: str  # "passed" | "failed" | "skipped"
    message: str = ""
    detail: str = ""


# ---------------------------------------------------------------- parsing

def label_from_path(path: str) -> str:
    stem = os.path.splitext(os.path.basename(path))[0]
    if stem == "unit":
        return "Unit tests"
    if stem.startswith("ui-"):
        return "UI · " + stem[3:].replace("-", " ").strip()
    return stem.replace("-", " ").replace("_", " ").strip() or path


def parse_junit(path: str, run: str) -> list[Case]:
    if not os.path.isfile(path):
        return []
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError:
        return []
    cases: list[Case] = []
    for sn in root.iter("testsuite"):
        sname = sn.get("name") or "Tests"
        for tc in sn.findall("testcase"):
            cname = tc.get("name") or "?"
            ctime = float(tc.get("time") or 0.0)
            failure = tc.find("failure")
            error = tc.find("error")
            skipped = tc.find("skipped")
            if failure is not None or error is not None:
                node = failure if failure is not None else error
                cases.append(Case(run, sname, cname, ctime, "failed",
                                  message=(node.get("message") or "").strip(),
                                  detail=(node.text or "").strip()))
            elif skipped is not None:
                cases.append(Case(run, sname, cname, ctime, "skipped",
                                  message=(skipped.get("message") or "").strip()))
            else:
                cases.append(Case(run, sname, cname, ctime, "passed"))
    return cases


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


# ---------------------------------------------------------------- rendering

def fmt_pct(x: float) -> str:
    return f"{x * 100:.1f}%"


def _n(cases: list[Case], status: str) -> int:
    return sum(1 for c in cases if c.status == status)


def build_markdown(cases: list[Case], run_order: list[str],
                   cov: dict | None, meta: dict) -> str:
    total = len(cases)
    passed, failed, skipped = _n(cases, "passed"), _n(cases, "failed"), _n(cases, "skipped")
    duration = sum(c.time for c in cases)
    overall = "✅ PASSED" if failed == 0 and total else ("❌ FAILED" if failed else "⚠️ NO TESTS")

    by_run: "OrderedDict[str, list[Case]]" = OrderedDict((r, []) for r in run_order)
    for c in cases:
        by_run.setdefault(c.run, []).append(c)

    L: list[str] = [f"# Test Report — {overall}", ""]
    if meta:
        L += ["| | |", "|---|---|"]
        for k in ("Repository", "Branch", "Commit", "Message", "Run", "Generated"):
            if meta.get(k):
                L.append(f"| **{k}** | {meta[k]} |")
        L.append("")
    L += [f"**{passed} passed**, **{failed} failed**, **{skipped} skipped** "
          f"— {total} tests across {len(by_run)} run(s) in {duration:.0f}s", ""]

    # ---- per-run / per-device table
    L += ["## Runs", "", "| Run | Result | Tests | ✅ | ❌ | ⏭️ | Time |",
          "|---|:--:|--:|--:|--:|--:|--:|"]
    for run, cs in by_run.items():
        f = _n(cs, "failed")
        res = "✅" if f == 0 and cs else ("❌" if f else "—")
        L.append(f"| {run} | {res} | {len(cs)} | {_n(cs,'passed')} | "
                 f"{f} | {_n(cs,'skipped')} | {sum(c.time for c in cs):.0f}s |")
    L.append("")

    # ---- failures
    fails = [c for c in cases if c.status == "failed"]
    if fails:
        L += ["## Failures", ""]
        for c in fails:
            L += [f"### ❌ `{c.suite}.{c.name}`  —  _{c.run}_", ""]
            if c.message:
                L += [f"> {c.message}", ""]
            if c.detail and c.detail != c.message:
                L += ["```", "\n".join(c.detail.splitlines()[:20]), "```", ""]

    # ---- per-suite table (only meaningful when there's a single run)
    if len(by_run) == 1:
        suites = sorted({c.suite for c in cases})
        L += ["## Suites", "", "| Suite | Tests | ✅ | ❌ | ⏭️ | Time |",
              "|---|--:|--:|--:|--:|--:|"]
        for s in suites:
            cs = [c for c in cases if c.suite == s]
            L.append(f"| {s} | {len(cs)} | {_n(cs,'passed')} | {_n(cs,'failed')} | "
                     f"{_n(cs,'skipped')} | {sum(c.time for c in cs):.1f}s |")
        L.append("")

    # ---- coverage
    if cov and cov.get("targets"):
        L += ["## Code coverage", "",
              "| Target | Coverage | Covered / Executable lines |", "|---|--:|--:|"]
        tot_cov = tot_exe = 0
        for t in sorted(cov["targets"], key=lambda t: t.get("name", "")):
            covd, exe = t.get("coveredLines", 0), t.get("executableLines", 0)
            tot_cov += covd
            tot_exe += exe
            L.append(f"| {t.get('name','?')} | {fmt_pct(t.get('lineCoverage',0.0))} | {covd} / {exe} |")
        if tot_exe:
            L.append(f"| **Overall** | **{fmt_pct(tot_cov/tot_exe)}** | **{tot_cov} / {tot_exe}** |")
        L.append("")

    # ---- passing list (collapsed)
    passes = [c for c in cases if c.status == "passed"]
    if passes:
        L += ["<details><summary>Passing tests</summary>", ""]
        for run, cs in by_run.items():
            ok = [c for c in cs if c.status == "passed"]
            if not ok:
                continue
            L.append(f"**{run}**")
            L.append("")
            for c in ok:
                L.append(f"- `{c.suite}.{c.name}` ({c.time:.2f}s)")
            L.append("")
        L += ["</details>", ""]

    return "\n".join(L)


def _inline(text: str) -> str:
    esc = html.escape(text)
    esc = re.sub(r"\[([^\]]+)\]\((https?://[^)]+)\)", r'<a href="\2">\1</a>', esc)
    esc = re.sub(r"`([^`]+)`", r"<code>\1</code>", esc)
    esc = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", esc)
    esc = re.sub(r"_([^_]+)_", r"<em>\1</em>", esc)
    return esc


def markdown_to_html(md: str, title: str) -> str:
    out: list[str] = []
    in_code = in_table = False
    for line in md.splitlines():
        if line.startswith("```"):
            out.append("</pre>" if in_code else "<pre>")
            in_code = not in_code
            continue
        if in_code:
            out.append(html.escape(line))
            continue
        if line.startswith("<details") or line.startswith("</details"):
            out.append(line)
            continue
        if line.strip() == "":
            if in_table:
                out.append("</table>")
                in_table = False
            continue
        if line.startswith("|"):
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if set("".join(cells)) <= set("-: "):
                continue
            if not in_table:
                out.append("<table>")
                in_table = True
            out.append("<tr>" + "".join(f"<td>{_inline(c)}</td>" for c in cells) + "</tr>")
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
 body{{font:14px -apple-system,Segoe UI,Roboto,sans-serif;max-width:960px;margin:2rem auto;padding:0 1rem;color:#1c1c1e}}
 h1{{border-bottom:2px solid #e5e5ea;padding-bottom:.3rem}}
 h2{{margin-top:2rem;border-bottom:1px solid #e5e5ea;padding-bottom:.2rem}}
 table{{border-collapse:collapse;width:100%;margin:.5rem 0}}
 th,td{{border:1px solid #d1d1d6;padding:.4rem .6rem;text-align:left}}
 th{{background:#f2f2f7}}
 pre{{background:#f6f8fa;border:1px solid #e5e5ea;border-radius:6px;padding:.6rem;overflow:auto;font:12px SFMono-Regular,Menlo,monospace}}
 blockquote{{margin:.4rem 0;padding:.2rem .8rem;border-left:3px solid #ff9500;background:#fff8ef}}
 .li{{margin:.1rem 0}} details{{margin:.6rem 0}}
</style></head><body>
{body}
</body></html>"""


def _which(name: str) -> str | None:
    for d in os.environ.get("PATH", "").split(os.pathsep):
        p = os.path.join(d, name)
        if os.path.isfile(p) and os.access(p, os.X_OK):
            return p
    return None


def try_pdf(html_path: str, pdf_path: str) -> str | None:
    candidates = [
        ["weasyprint", html_path, pdf_path],
        ["pandoc", html_path, "-o", pdf_path],
        ["wkhtmltopdf", "--quiet", html_path, pdf_path],
    ]
    for br in ("google-chrome", "chromium", "chromium-browser",
               "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"):
        candidates.append([br, "--headless", "--disable-gpu", "--no-pdf-header-footer",
                           f"--print-to-pdf={pdf_path}", f"file://{os.path.abspath(html_path)}"])
    for cmd in candidates:
        exe = cmd[0]
        if not (exe if os.path.isabs(exe) and os.path.exists(exe) else _which(exe)):
            continue
        try:
            subprocess.run(cmd, check=True, capture_output=True, timeout=120)
            if os.path.isfile(pdf_path) and os.path.getsize(pdf_path) > 0:
                return exe
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
            continue
    return None


def collect_meta() -> dict:
    e = os.environ.get
    sha = e("GITHUB_SHA", "")
    server = e("GITHUB_SERVER_URL", "https://github.com")
    repo = e("GITHUB_REPOSITORY", "")
    run_id = e("GITHUB_RUN_ID", "")
    msg = (e("GIT_COMMIT_MESSAGE", "") or "").splitlines()
    meta = {
        "Repository": repo,
        "Branch": e("GITHUB_REF_NAME", ""),
        "Commit": f"`{sha[:7]}`" if sha else "",
        "Message": msg[0] if msg else "",
        "Run": f"[{run_id}]({server}/{repo}/actions/runs/{run_id})" if run_id and repo else "",
        "Generated": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC"),
    }
    return {k: v for k, v in meta.items() if v}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--junit", nargs="+", required=True,
                    help='One or more "LABEL=path" or "path" (globs ok).')
    ap.add_argument("--xcresult", default="")
    ap.add_argument("--out-dir", default="build/report")
    args = ap.parse_args()

    # Expand each --junit arg into (label, path) pairs.
    pairs: list[tuple[str, str]] = []
    for raw in args.junit:
        label, _, spec = raw.partition("=") if "=" in raw else ("", "", raw)
        for path in sorted(glob.glob(spec)) or [spec]:
            pairs.append((label or label_from_path(path), path))

    cases: list[Case] = []
    run_order: list[str] = []
    for label, path in pairs:
        if label not in run_order:
            run_order.append(label)
        got = parse_junit(path, label)
        if not got:
            print(f"::warning::no test cases parsed from {path}", file=sys.stderr)
        cases += got

    os.makedirs(args.out_dir, exist_ok=True)
    md = build_markdown(cases, run_order, coverage_from_xcresult(args.xcresult), collect_meta())

    md_path = os.path.join(args.out_dir, "test-report.md")
    html_path = os.path.join(args.out_dir, "test-report.html")
    pdf_path = os.path.join(args.out_dir, "test-report.pdf")
    with open(md_path, "w") as f:
        f.write(md)
    with open(html_path, "w") as f:
        f.write(markdown_to_html(md, "Test Report"))
    print(f"wrote {md_path}\nwrote {html_path}")

    engine = try_pdf(html_path, pdf_path)
    print(f"wrote {pdf_path} (via {engine})" if engine else
          "::notice::no HTML->PDF converter on runner (weasyprint / pandoc / wkhtmltopdf / chrome); skipping PDF")

    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a") as f:
            f.write(md + "\n")

    failed, total = _n(cases, "failed"), len(cases)
    print(f"report: {total - failed}/{total} passed" + (f", {failed} failed" if failed else ""))
    return 0  # gating is the test step's job, not this one


if __name__ == "__main__":
    sys.exit(main())
