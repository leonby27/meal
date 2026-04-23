#!/usr/bin/env bash
# Build an iOS IPA with strict version verification.
#
# Why this exists: `flutter build ipa` can fail at the export step (e.g. missing
# signing cert) while leaving a STALE .ipa from a previous build in
# build/ios/ipa/. Naive copy-to-Desktop scripts then ship the old build with a
# new filename. This script guards against that by:
#   1. Reading version + buildNumber from pubspec.yaml and build_info.dart
#      and failing if they disagree.
#   2. Deleting build/ios/ipa/*.ipa before the build so we can't pick up a
#      stale artefact.
#   3. Verifying CFBundleVersion inside the freshly produced .ipa matches
#      pubspec.yaml before copying to Desktop.
#
# Usage: ./build-ipa.sh

set -euo pipefail

cd "$(dirname "$0")/app"

RED=$'\033[31m'
GRN=$'\033[32m'
YLW=$'\033[33m'
RST=$'\033[0m'

die()  { echo "${RED}✗ $*${RST}" >&2; exit 1; }
info() { echo "${YLW}➜ $*${RST}"; }
ok()   { echo "${GRN}✓ $*${RST}"; }

# ---- 1. Read versions from source of truth ---------------------------------

PUBSPEC_VERSION=$(awk '/^version:/ {print $2}' pubspec.yaml)
[[ -n "$PUBSPEC_VERSION" ]] || die "Could not read version from pubspec.yaml"

PUBSPEC_NAME=${PUBSPEC_VERSION%+*}
PUBSPEC_BUILD=${PUBSPEC_VERSION#*+}

if [[ "$PUBSPEC_NAME" == "$PUBSPEC_VERSION" || -z "$PUBSPEC_BUILD" ]]; then
  die "pubspec.yaml version '$PUBSPEC_VERSION' must be in form X.Y.Z+N"
fi

BUILD_INFO_NUM=$(awk -F'[= ;]+' '/buildNumber/ {print $4}' lib/core/build_info.dart)
[[ -n "$BUILD_INFO_NUM" ]] || die "Could not read buildNumber from lib/core/build_info.dart"

info "pubspec.yaml       : $PUBSPEC_NAME+$PUBSPEC_BUILD"
info "build_info.dart    : $BUILD_INFO_NUM"

if [[ "$PUBSPEC_BUILD" != "$BUILD_INFO_NUM" ]]; then
  die "buildNumber mismatch: pubspec=$PUBSPEC_BUILD, build_info.dart=$BUILD_INFO_NUM (update both)"
fi
ok "version sources are in sync"

# ---- 2. Clean stale artefacts so we can't accidentally ship an old IPA ------

IPA_DIR="build/ios/ipa"
if [[ -d "$IPA_DIR" ]]; then
  info "cleaning $IPA_DIR/*.ipa (and stale archive)"
  rm -f "$IPA_DIR"/*.ipa
fi
rm -rf build/ios/archive

# ---- 3. Build ---------------------------------------------------------------

info "running flutter build ipa --release ..."
flutter build ipa --release

# ---- 4. Verify the produced IPA --------------------------------------------

IPA_PATH=$(ls -t "$IPA_DIR"/*.ipa 2>/dev/null | head -n1 || true)
[[ -n "$IPA_PATH" && -f "$IPA_PATH" ]] || die "No .ipa found in $IPA_DIR — build or export failed. Check logs and your Xcode signing (Xcode → Settings → Accounts)."

# Extract CFBundleVersion / CFBundleShortVersionString from the freshly built IPA.
# Info.plist is stored in binary form inside the IPA, so extract to a temp file
# (plutil cannot read binary plist from stdin reliably).
TMP_PLIST=$(mktemp -t mealtracker-info.XXXXXX).plist
trap 'rm -f "$TMP_PLIST"' EXIT
unzip -p "$IPA_PATH" "Payload/Runner.app/Info.plist" > "$TMP_PLIST"
[[ -s "$TMP_PLIST" ]] || die "Could not read Info.plist inside $IPA_PATH"

ACTUAL_BUILD=$(plutil -extract CFBundleVersion raw "$TMP_PLIST")
ACTUAL_NAME=$(plutil -extract CFBundleShortVersionString raw "$TMP_PLIST")

info "IPA CFBundleShortVersionString : $ACTUAL_NAME"
info "IPA CFBundleVersion            : $ACTUAL_BUILD"

if [[ "$ACTUAL_BUILD" != "$PUBSPEC_BUILD" || "$ACTUAL_NAME" != "$PUBSPEC_NAME" ]]; then
  die "IPA version ($ACTUAL_NAME+$ACTUAL_BUILD) does not match pubspec ($PUBSPEC_NAME+$PUBSPEC_BUILD)."
fi
ok "IPA version matches source"

# ---- 5. Copy to Desktop using the REAL version -----------------------------

DEST="$HOME/Desktop/Meal Tracker ${ACTUAL_NAME} (${ACTUAL_BUILD}).ipa"
cp "$IPA_PATH" "$DEST"
ok "copied to: $DEST"
