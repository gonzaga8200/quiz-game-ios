# Sourced by the other scripts. Xcode is used through DEVELOPER_DIR, so `xcode-select` can keep
# pointing at the Command Line Tools.
if [ -z "${DEVELOPER_DIR:-}" ] && [ -d /Applications/Xcode.app ]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IOS_VERSION="${IOS_VERSION:-26.5}"
IPHONE="${IPHONE:-iPhone 17 Pro}"
IPAD="${IPAD:-iPad Pro 13-inch (M5)}"
DERIVED="${DERIVED:-$REPO_ROOT/build/DerivedData}"
destination() { echo "platform=iOS Simulator,name=$1,OS=$IOS_VERSION"; }
