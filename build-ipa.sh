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
# Make absolute so later steps that `cd` into a tmp dir keep working.
IPA_PATH=$(cd "$(dirname "$IPA_PATH")" && pwd)/$(basename "$IPA_PATH")

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

# ---- 5. Patch frameworks whose arm64 slice was built with PLATFORM=
#         IOSSIMULATOR (App Store rejects them as "Invalid executable").
#
# Recent versions of `objective_c` (and other Dart FFI packages that use
# the native_assets build hook) ship a prebuilt arm64 framework whose
# LC_BUILD_VERSION load command is stamped with platform=IOSSIMULATOR
# even when the host project targets iOS device. The arm64 machine code
# itself is fine — only the metadata is wrong — so `vtool` can rewrite
# the platform marker in place. We then re-sign the framework and the
# enclosing app with the same Apple Distribution identity Xcode used,
# preserving entitlements / provisioning, and re-zip the IPA.
#
# This entire block is a no-op when no frameworks need fixing.

WORK_DIR=$(mktemp -d -t mealtracker-fix.XXXXXX)
cleanup_workdir() { rm -rf "$WORK_DIR"; }
trap 'rm -f "$TMP_PLIST"; cleanup_workdir' EXIT

(cd "$WORK_DIR" && unzip -q "$IPA_PATH")
APP_DIR="$WORK_DIR/Payload/Runner.app"
[[ -d "$APP_DIR" ]] || die "Unexpected IPA layout — no Payload/Runner.app"

# Pull the original signing identity off the .app so we re-sign with
# the same cert (Apple Distribution: <Team>) Xcode picked.
# Pipe with `| awk … exit` causes SIGPIPE on the upstream `codesign`,
# which `set -o pipefail` then propagates as a non-zero pipeline status
# even though we got the data we wanted. Buffer codesign's output first.
SIGN_INFO=$(codesign -dvv "$APP_DIR" 2>&1 || true)
SIGN_IDENT=$(echo "$SIGN_INFO" | awk -F= '/^Authority=Apple Distribution/ && !p {print $2; p=1}')
[[ -n "$SIGN_IDENT" ]] || die "Could not read signing identity from $APP_DIR"

PATCHED=0
while IFS= read -r FW; do
  BIN_NAME=$(plutil -extract CFBundleExecutable raw "$FW/Info.plist" 2>/dev/null || true)
  [[ -z "$BIN_NAME" ]] && BIN_NAME=$(basename "$FW" .framework)
  BIN="$FW/$BIN_NAME"
  [[ -f "$BIN" ]] || continue

  # Read all platforms across all slices; if any one is IOSSIMULATOR we
  # need to rewrite that slice. Most Dart FFI frameworks are arm64-only
  # at this point.
  BUILD_INFO=$(vtool -show-build "$BIN" 2>/dev/null || true)
  if echo "$BUILD_INFO" | awk '/platform/{print $2}' | grep -qx 'IOSSIMULATOR'; then
    SDK=$(echo "$BUILD_INFO" | awk '/sdk/ && !p {print $2; p=1}')
    # Apple's validator (90208) rejects a framework whose binary minOS
    # is GREATER than its Info.plist MinimumOSVersion. The simulator
    # slice we're rewriting was typically built with min 14.0 even when
    # the framework's Info.plist advertises 13.0, so derive minos from
    # the plist instead of carrying the simulator slice's value over.
    PLIST_MIN=$(plutil -extract MinimumOSVersion raw "$FW/Info.plist" \
      2>/dev/null || true)
    BIN_MIN=$(echo "$BUILD_INFO" | awk '/minos/ && !p {print $2; p=1}')
    MIN_OS="${PLIST_MIN:-$BIN_MIN}"
    info "patching $(basename "$FW") (was: IOSSIMULATOR min=$BIN_MIN; plist=$PLIST_MIN; using min=$MIN_OS, sdk=$SDK)"
    vtool -arch arm64 \
      -set-build-version ios "$MIN_OS" "$SDK" \
      -tool ld 1230.1 \
      -replace \
      -output "$BIN" "$BIN" 2>/dev/null
    codesign --force --sign "$SIGN_IDENT" \
      --preserve-metadata=identifier,entitlements,flags "$FW" \
      || die "codesign failed for $FW"
    PATCHED=$((PATCHED + 1))
  fi
done < <(find "$APP_DIR/Frameworks" -name '*.framework' -type d)

if [[ "$PATCHED" -gt 0 ]]; then
  info "re-signing Runner.app with: $SIGN_IDENT"
  codesign --force --sign "$SIGN_IDENT" \
    --preserve-metadata=identifier,entitlements,flags "$APP_DIR" \
    || die "codesign failed for Runner.app"

  info "re-zipping IPA"
  rm -f "$IPA_PATH"
  (cd "$WORK_DIR" && zip -X -qr "$IPA_PATH" .)
  ok "patched $PATCHED framework(s) and re-signed IPA"
else
  ok "no IOSSIMULATOR-stamped frameworks found, IPA untouched"
fi

# ---- 6. Copy to Desktop using the REAL version -----------------------------

DEST="$HOME/Desktop/Meal Tracker ${ACTUAL_NAME} (${ACTUAL_BUILD}).ipa"
cp "$IPA_PATH" "$DEST"
ok "copied to: $DEST"
