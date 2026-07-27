#!/usr/bin/env bash
# 版本住在两个地方,而且已经漂过一次:提交 5598985 把 marketplace.json 升到 0.2.3,
# 却漏了 SKILL.md 的 metadata.version —— 它在 0.2.2 上停了整整一个版本,
# 没有任何东西会报错。这个脚本存在的唯一理由就是那次。
#
#   ./scripts/bump-version.sh 0.2.4
set -euo pipefail

new="${1:-}"
if [[ ! "$new" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  echo "usage: $0 <semver>   e.g. $0 0.2.4" >&2
  exit 1
fi

cd "$(dirname "$0")/.."

current=$(jq -r .version marketplace.json)
echo "Bumping $current -> $new"

tmp=$(mktemp)
jq --arg v "$new" '.version = $v' marketplace.json > "$tmp" && mv "$tmp" marketplace.json

# SKILL.md 的 frontmatter 里那一行:`  version: 0.2.3`(缩进两格,在 metadata: 下面)
perl -0pi -e "s/^(  version: )\S+$/\${1}$new/m" SKILL.md

mk=$(jq -r .version marketplace.json)
sk=$(perl -ne 'print "$1\n" if /^  version: (\S+)$/' SKILL.md | head -1)
printf "%-22s %s\n" "marketplace.json" "$mk"
printf "%-22s %s\n" "SKILL.md" "$sk"
if [ "$mk" != "$sk" ]; then
  echo "两处不一致 —— 别提交" >&2
  exit 1
fi
echo
echo "两处一致。接着写 CHANGELOG,然后 commit + push(这个包走 git 分发,不发 npm)。"
