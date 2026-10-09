#!/bin/bash
set -euo pipefail

# Feeds the Simulator's real location service the "gachibowli circle_path.gpx" route
# (GoInfoGame/Resources/gachibowli circle_path.gpx - the same file already wired into
# this scheme's LaunchAction for manual Xcode Run use) before running the Map screen UI
# tests, then runs them.
#
# This only reaches MapLibre's own internal user-location layer (the My Location
# button's recenter, the "You Are Here" annotation, tracking mode) - it does NOT affect
# MapViewModel's camera-centering/OSM-fetch logic, which stays on the app's own fixed
# Kondapur mock in LocationManagerDelegate.swift by design (see that file's comment).
# That mock exists specifically because `xcrun simctl location set` (a single fixed
# point) was found unreliable in this project; this script uses the newer, route-based
# `simctl location start` instead, which `simctl` only accepts as explicit lat,lon pairs
# on the command line, not as a GPX path - so the waypoints are parsed out of the GPX
# file here at run time rather than duplicated by hand.
#
# Usage: Scripts/run-map-ui-tests-with-location.sh ["<simulator name>"] [-- <extra xcodebuild args>]
#   Scripts/run-map-ui-tests-with-location.sh
#   Scripts/run-map-ui-tests-with-location.sh "iPhone 15 Pro"
#   Scripts/run-map-ui-tests-with-location.sh "iPhone 15" -- -only-testing:GoInfoGameUITests/MapScreenUITestCases/testMyLocationButtonRecentersAlongGachibowliRoute

cd "$(dirname "$0")/.."

DEVICE="${1:-iPhone 15}"
if [[ "${2:-}" == "--" ]]; then
    shift 2
    EXTRA_ARGS=("$@")
else
    EXTRA_ARGS=(-only-testing:GoInfoGameUITests/MapScreenUITestCases)
fi

GPX_PATH="$(pwd)/GoInfoGame/Resources/gachibowli circle_path.gpx"
if [[ ! -f "$GPX_PATH" ]]; then
    echo "error: GPX route not found at $GPX_PATH" >&2
    exit 1
fi

WAYPOINTS=()
while IFS= read -r line; do
    WAYPOINTS+=("$line")
done < <(grep -oE 'lat="[0-9.-]+" lon="[0-9.-]+"' "$GPX_PATH" | sed -E 's/lat="([0-9.-]+)" lon="([0-9.-]+)"/\1,\2/')

if [[ "${#WAYPOINTS[@]}" -lt 2 ]]; then
    echo "error: found fewer than 2 waypoints in $GPX_PATH - simctl location start needs at least 2" >&2
    exit 1
fi

# Resolve ONE specific simulator up front and use its UDID for everything below. A name is
# ambiguous here (several runtimes each have an "iPhone 15"), and `simctl location booted`
# targets whichever device happens to be booted - which is not necessarily the one
# xcodebuild then runs the tests on. Feeding the route to a different device than the one
# under test looks exactly like "the route doesn't work" (seen directly: the only booted
# simulator was an iPhone 17 Pro while the tests ran on a freshly booted iPhone 15).
# When several runtimes have a device with that name, the NEWEST is used (simctl lists
# runtimes oldest-first, so that is the last match) - route playback reaching MapLibre's
# user-location layer was confirmed on iOS 26.5 and did NOT work on iOS 17.0 (the test
# skips there rather than failing: "You Are Here" never gets an on-screen position).
DEVICE_LINE="$(xcrun simctl list devices available | grep -F "    $DEVICE (" | tail -1 || true)"
UDID="$(echo "$DEVICE_LINE" | grep -Eo '[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}' | head -1 || true)"
if [[ -z "$UDID" ]]; then
    echo "error: no available simulator named \"$DEVICE\" - see: xcrun simctl list devices available" >&2
    exit 1
fi
echo "Using simulator \"$DEVICE\" ($UDID)"

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null

cleanup() {
    echo "Stopping Gachibowli route playback on $UDID..."
    xcrun simctl location "$UDID" clear || true
}
trap cleanup EXIT

echo "Starting Gachibowli route playback (${#WAYPOINTS[@]} waypoints)..."
xcrun simctl location "$UDID" start "${WAYPOINTS[@]}"

xcodebuild test \
    -workspace GoInfoGame.xcworkspace \
    -scheme GoInfoGame \
    -destination "platform=iOS Simulator,id=$UDID" \
    "${EXTRA_ARGS[@]}"
