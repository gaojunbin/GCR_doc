#!/bin/sh
#
# Mirror the GCR repository into this site, so that gcr.junbingao.com can serve
# the installer and the source it installs from.
#
# Published into html/:
#
#   install.sh   the installer, so `curl -fsSL https://gcr.junbingao.com/install.sh | sh` works
#   gcr.tar.gz   the repository, unpacking to GCR/
#   gcr.commit   the commit the mirror currently sits on
#
# Run it from cron on the machine serving the site, for example:
#
#   */10 * * * * /opt/GCR_doc/sync-gcr.sh >> /var/log/gcr-sync.log 2>&1
#
# The published files are generated, not tracked in git.
#
set -eu

PATH=/usr/local/bin:/usr/bin:/bin:$PATH

REPO_URL=${GCR_REPO_URL:-https://github.com/gaojunbin/GCR.git}
REPO_BRANCH=${GCR_REPO_BRANCH:-master}

here=$(cd "$(dirname "$0")" && pwd)
mirror=$here/.gcr-mirror
html=$here/html
lock=$here/.sync-gcr.lock
stage=$here/.sync-gcr.stage

log() {
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

# mkdir is atomic, so overlapping cron runs cannot fight over the mirror.
if ! mkdir "$lock" 2>/dev/null; then
    log "another sync is running, skipped"
    exit 0
fi
trap 'rm -rf "$lock" "$stage"' EXIT

if [ -d "$mirror/.git" ]; then
    git -C "$mirror" fetch --quiet --depth 1 origin "$REPO_BRANCH"
    git -C "$mirror" reset --quiet --hard FETCH_HEAD
else
    rm -rf "$mirror"
    git clone --quiet --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$mirror"
fi

commit=$(git -C "$mirror" rev-parse HEAD)
if [ -f "$html/gcr.commit" ] && [ "$(cat "$html/gcr.commit")" = "$commit" ]; then
    log "already at $commit"
    exit 0
fi

# Build everything aside first, then move it in, so a request never reads a
# half written tarball.
rm -rf "$stage"
mkdir -p "$stage"
git -C "$mirror" archive --format=tar.gz --prefix=GCR/ HEAD > "$stage/gcr.tar.gz"
cp "$mirror/install_gcr.sh" "$stage/install.sh"
printf '%s\n' "$commit" > "$stage/gcr.commit"
chmod 644 "$stage/gcr.tar.gz" "$stage/install.sh" "$stage/gcr.commit"

mv "$stage/gcr.tar.gz" "$html/gcr.tar.gz"
mv "$stage/install.sh" "$html/install.sh"
mv "$stage/gcr.commit" "$html/gcr.commit"

log "published $commit"
