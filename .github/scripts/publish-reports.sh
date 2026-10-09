#!/usr/bin/env bash
# Attaches CI report files to the "ios-ci-reports" pre-release and links them from the job's
# summary page, then deletes that release's assets older than RETENTION_DAYS.
#
# Used instead of actions/upload-artifact: from this self-hosted runner its very first request
# (CreateArtifact, made before any bytes are sent) times out on every attempt, so no artifact is
# ever created. Release assets go through uploads.github.com instead, don't count against the
# artifact storage quota, and don't grow the git repo (the release only holds files). Same
# approach as the Android repo's .github/scripts/publish-reports.sh.
#
# Tag is "ios-ci-reports", not "ci-reports": an earlier workflow version pushed a *branch*
# called ci-reports to this repo, and a tag with the same name would be ambiguous.
#
# Needs the gh CLI on the runner and GH_TOKEN with contents: write (to create the release/tag
# and upload/delete its assets).
#
# Usage: publish-reports.sh <file> [<file> ...]   (missing files are skipped with a warning)
set -euo pipefail

tag="ios-ci-reports"
retention_days=14

command -v gh >/dev/null || { echo "::error::gh CLI not found on this runner (brew install gh)"; exit 1; }

files=()
for f in "$@"; do
  if [ -f "$f" ]; then files+=("$f"); else echo "::warning::$f not found - skipping"; fi
done
if [ "${#files[@]}" -eq 0 ]; then
  echo "::warning::no report files to publish"
  exit 0
fi

# Two runs (e.g. a push and the Friday schedule) can race to create the release the first time -
# if the create fails, the other run has won the race, as long as the release exists now
if ! gh release view "$tag" >/dev/null 2>&1; then
  gh release create "$tag" --prerelease --target "$GITHUB_SHA" --title "iOS CI reports" \
    --notes "Test report files from iOS CI runs, linked from each run's summary page. Files older than $retention_days days are deleted automatically." \
    || gh release view "$tag" >/dev/null
fi

base_url="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/releases/download/$tag"
{
  echo "## Test reports"
  echo "Attached to the [$tag]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/releases/tag/$tag) pre-release, kept for $retention_days days:"
} >> "$GITHUB_STEP_SUMMARY"

for file in "${files[@]}"; do
  # run id + attempt in the name, since all runs share this one release (a re-run gets its own
  # file instead of replacing the reports of the attempt before it)
  name="${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}-$(basename "$file")"
  staged="$RUNNER_TEMP/$name"
  cp "$file" "$staged"
  gh release upload "$tag" "$staged" --clobber
  rm -f "$staged"
  echo "- [$name]($base_url/$name)" >> "$GITHUB_STEP_SUMMARY"
  echo "published: $base_url/$name"
done

# Delete assets older than the retention window. BSD date (macOS runner) first, GNU date as a
# fallback. Paginated by release id: the release object itself only embeds a limited asset list.
cutoff=$(date -u -v-"${retention_days}"d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
  || date -u -d "$retention_days days ago" +%Y-%m-%dT%H:%M:%SZ)
release_id=$(gh api "repos/$GITHUB_REPOSITORY/releases/tags/$tag" --jq .id)
gh api --paginate "repos/$GITHUB_REPOSITORY/releases/$release_id/assets?per_page=100" \
  --jq ".[] | select(.created_at < \"$cutoff\") | .id" |
  while read -r id; do
    gh api -X DELETE "repos/$GITHUB_REPOSITORY/releases/assets/$id" || echo "::warning::couldn't delete old asset $id"
  done
