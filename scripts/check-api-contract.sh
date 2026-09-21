#!/usr/bin/env bash
# 核对本 skill 的文档有没有和服务端的作用域契约漂开。
#
# ★★★ 为什么需要(2026-08-09)
#
# 服务端把 CMO 收进单个 workspace 那次,"feed 的作用域是什么"这一个事实同时写在
# 四个地方:Rails 控制器、autowhisper-mcp 的工具描述、本仓库的
# references/api-reference.md、SKILL.md。改了控制器,另外三份靠人记得跟上 ——
# 结果三份全留在旧契约上,对着 agent 说"这个接口跨全部工作区"。
#
# ★ 对 skill 来说【文档就是行为】。SKILL.md 不是给人读的说明,它是 agent 的行动
# 依据。写错了 agent 不会报错,只会照着错的做 —— 这次的具体后果是:agent 以为自己
# 看到了用户的全部内容,实际只看到一个工作区,而它不知道。
#
# 这和 bump-version.sh 是同一个病:一个事实住在多处,没有任何东西会报错。
# 那个脚本管版本,这个管契约。
#
#   ./scripts/check-api-contract.sh
#   AUTOWHISPER_CONTRACT_URL=http://localhost:3000/api/contract ./scripts/check-api-contract.sh
set -euo pipefail

URL="${AUTOWHISPER_CONTRACT_URL:-https://autowhisper.xyz/api/contract}"
DOC="references/api-reference.md"
SKILL="SKILL.md"

cd "$(dirname "$0")/.."

CONTRACT="$(curl -fsS --max-time 10 "$URL" 2>/dev/null || true)"
if [ -z "$CONTRACT" ]; then
  # ⚠️ 拉不到就【跳过并显式说出来】,绝不静默通过。一个连不上就默默变绿的检查,
  # 和没有这个检查是一回事,而且更糟:它看着像有防护。
  echo "⏭  拉不到契约($URL)—— 跳过,没有验证任何东西"
  exit 0
fi

fail=0
note() { echo "❌ $1"; fail=1; }

# ── ① 服务端已经不返回的 scope 取值,不许还出现在文档的示例里 ──────────────
# agent 会照着示例判断自己拿到的是什么。示例写 "scope":"account" 而服务端返回
# "workspace",agent 要么困惑,要么按错的分支走。
allowed="$(printf '%s' "$CONTRACT" | python3 -c 'import json,sys; print(" ".join(json.load(sys.stdin)["scope_field_values"]))')"
for v in $(grep -oE '"scope":"[a-z]+"' "$DOC" | sed 's/.*:"//;s/"//' | sort -u); do
  case " $allowed " in
    *" $v "*) ;;
    *) note "$DOC 的示例里有 \"scope\":\"$v\",但服务端只会返回:$allowed" ;;
  esac
done

# ── ② workspace 作用域的接口,文档不许说它跨全部工作区 ────────────────────
ws_paths="$(printf '%s' "$CONTRACT" | python3 -c '
import json,sys
d=json.load(sys.stdin)
print("\n".join(e["path"] for e in d["endpoints"] if e["scope"]=="workspace"))')"
while IFS= read -r p; do
  [ -z "$p" ] && continue
  grep -q -- "$p" "$DOC" || continue
  # 该接口那一段里若出现"跨全部工作区"的说法,就是旧契约残留。
  # ⚠️ 必须【精确】匹配标题里的路径,不能用子串:/api/products 是
  # /api/products/summary 的前缀,子串匹配会把 summary 那一段也算进来 ——
  # 而 summary 本来就该是账号级,于是报一个假阳性。第一次跑就踩中了。
  section="$(awk -v pat="$p" '
    /^### /{
      inside = 0
      n = split($0, f, " ")
      if (n >= 3 && f[3] == pat) inside = 1
    }
    inside {print}
  ' "$DOC")"
  # 只抓【声称本接口跨工作区】的说法,不抓 "account-wide" 这个词本身 ——
  # "for account-wide totals use /api/products/summary" 是在【指路】,是对的。
  # 第一版按词命中,把这句正确的话也报成了错。判据是句子在说谁,不是出现了哪个词。
  if printf '%s' "$section" | grep -qiE "across [*]*all active workspaces|Lists .*across .*all .*workspaces|Account-wide by default|spans (every|all) (active )?workspace"; then
    note "$DOC 里 $p 那一段仍写着跨全部工作区,但契约说它是单工作区的"
  fi
done <<< "$ws_paths"

# ── ③ 收窄作用域后必须指出发现出口,否则调用方锁死在第一个工作区 ──────────
disc="$(printf '%s' "$CONTRACT" | python3 -c '
import json,sys
d=json.load(sys.stdin)
print("\n".join(e["path"] for e in d["endpoints"] if e.get("discovery")))')"
if [ -n "$disc" ]; then
  found=0
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    grep -q -- "$p" "$DOC" && found=1
  done <<< "$disc"
  [ "$found" = 1 ] || note "$DOC 没有提到任何发现入口($(echo "$disc" | tr '\n' ' '))—— agent 无从知道还有哪些工作区"
fi

# ── ⑤ 动作工具清单必须与契约一致(2026-09-21 补) ────────────────────────
# 为什么加:boost_post 服务端 2026-08-28 上线,本文档一直只列八个工具,漏了三周
# 没有任何东西报错 —— 而 agent 只会照着文档给的清单去调,所以那个能力实际上
# 【不存在】。①~④ 守的是作用域,守不住"服务端多了一个工具"这类漂移。
#
# ⚠️⚠️ 判据必须钉在【那份清单本身】,不是"全文出现过这个词"。第一版 grep 整个
#    文件,于是下面那段解释 boost_post 为什么曾经漏掉的散文也算数 —— 把工具从
#    清单里删掉,检查照样绿。写完当场验过才发现:守卫钉了措辞,没钉事实。
#
# ⚠️ 契约在 2026-09-21 之前不发布 direct_action_tools。拿不到就跳过【并说出来】,
#    不静默通过 —— 同本文件顶部那条纪律。
tools="$(printf '%s' "$CONTRACT" | python3 -c '
import json,sys
d=json.load(sys.stdin)
print("\n".join(t["name"] for t in d.get("direct_action_tools", [])))')"
if [ -z "$tools" ]; then
  echo "⏭  这个契约没有 direct_action_tools(服务端早于 2026-09-21)—— 跳过工具清单核对"
else
  # 只取 "Supported `:tool` values:" 之后、到空行为止的那几行 —— 那才是清单。
  tool_list="$(awk '
    /Supported `:tool` values:/ { grab = 1; next }
    grab && /^[[:space:]]*$/     { exit }
    grab                         { print }
  ' "$DOC")"
  if [ -z "$tool_list" ]; then
    note "$DOC 里找不到 'Supported \`:tool\` values:' 那份清单 —— 清单换了写法就必须同步改这个判据,否则它会静默变成永远绿"
  else
    while IFS= read -r t; do
      [ -z "$t" ] && continue
      printf '%s' "$tool_list" | grep -q "\`$t\`" \
        || note "契约声明了工具 $t,$DOC 的清单里却没有 —— agent 看不到的能力等于不存在(boost_post 就这么漏了三周)"
    done <<< "$tools"

    # 反向:清单列了契约没有的工具 ⇒ agent 会去调一个服务端不认的名字。
    for t in $(printf '%s' "$tool_list" | grep -oE '`[a-z_]+`' | tr -d '`' | sort -u); do
      printf '%s\n' "$tools" | grep -qx "$t" \
        || note "$DOC 的清单里有 $t,但契约没有它 —— agent 会调一个服务端不认的名字"
    done
  fi
fi

# ── ④ SKILL.md 必须写明 CMO 只看得见一个工作区 ──────────────────────────
# 这是 agent 最容易做错的一件事:点名别的工作区的产品,以为 CMO 够得到。
grep -qi "only sees ONE workspace" "$SKILL" \
  || note "$SKILL 没有说明 CMO 只能看到当前工作区 —— agent 会以为它够得着别处的产品"

if [ "$fail" = 0 ]; then
  echo "✅ 文档与服务端契约一致($(printf '%s' "$CONTRACT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["version"])'))"
else
  echo
  echo "服务端契约的单一数据源是 autowhisper 仓库的 app/services/api/contract.rb。"
  echo "契约变了就要同步这里的文档 —— 对 agent 来说文档就是行为。"
  exit 1
fi
