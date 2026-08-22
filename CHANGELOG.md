# Changelog

## 0.4.0
- **`poll` and `confirm` are workspace-scoped — pass the same `workspace_id` you
  sent the message with, or they 404.** Documented the failure and added the
  `$WS` capture step; hardened it against `jq -r '.current_workspace.id'`
  silently printing the literal string `"null"` (which the server treats as a
  present, non-empty value and 404s on) instead of falling back correctly.
- **`actions[]` corrected to match reality, not the intended design.** The
  tool-call log and the button-style cards collide on the same jsonb column
  server-side (a symbol key vs. a string key) — the string key wins. A turn
  that produced button cards silently has no tool-call log in `actions[]`
  anymore. Docs now say so and point at `cards` (unaffected, separate keys)
  as the reliable place to read a lifted payload from. Server behavior itself
  is unchanged; this is a documentation correction, tracked as a known
  limitation for separate work.
- **Poll timing consistent everywhere.** Removed the leftover "a turn
  typically completes in seconds" line — the branch had already settled on a
  3-minute poll ceiling elsewhere (grounded ad advice measured over two
  minutes in production), and the old line contradicted it.
- **Documented `activation_guidance.ad_plan_cta`** — the one-click "get your
  ad plan" affordance the server sends once a platform is connected. Agents
  can now show it as a button and fire it as a normal chat turn.
- **Added a real pointer for the ads-MCP handover.** "Connect Meta's official
  Ads MCP" used to give the reader nothing to act on. Now links Meta's own
  first-party developer docs — deliberately not a third-party npm package,
  since this is also where an owner pastes an API token.

## 0.3.0
- **The CMO now only sees ONE workspace.** Server-side change on 2026-08-09:
  the chat is scoped to the workspace you pass — it can list, name and act on
  that workspace's products and nothing else. Naming a product that lives in
  another workspace gets "I don't see it in this workspace", not a
  cross-workspace action and not a silent substitution with a different product.
  Each workspace also has its **own conversation history**, so switching
  `workspace_id` switches which conversation you are in.
- **The read endpoints stopped spanning the account.** `/api/cmo/feed`,
  `/api/posts`, `/api/platforms` and `/api/products` used to return every active
  workspace when `workspace_id` was omitted; they now return the user's current
  workspace only. `scope` is always `"workspace"` — the `"account"` value is
  gone. Nothing breaks, but an agent that omitted the param and believed it was
  seeing everything now silently sees less, which is why this is a minor bump
  and not a patch.
- **Added the discovery route the narrower scope needs.** `/api/cmo/status` now
  carries a `workspaces` directory (every active workspace, its id, and a
  `current` flag). Call it first: it is how you learn which workspaces exist and
  which id to pass. `/api/products/summary` remains the one account-wide read.
- Corrected the reference doc, which described the old contract in six places —
  including a line claiming `/api/platforms` "can never disagree with
  `/api/cmo/status`'s counts". That was written to paper over a real
  inconsistency: platforms spanned every workspace while `status` reported a
  single `current_workspace`. Both are scoped the same way now, so the claim is
  finally true.

## 0.2.5
- Said what approving actually does. `approve_feed_item` **publishes** — it
  schedules the piece to every connected platform right then, and a video draft
  also starts rendering and is charged for at that moment (~80 credits a clip).
  The skill previously described it as "approve the good ones", which reads like
  a bookmark; an agent approving nine cards was spending nine renders without
  either side saying so.
- Told the agent to read `scheduled` in the response. `0` means it went nowhere,
  and connecting a platform afterwards does **not** send it retroactively — so
  reporting a bare "approved" leaves the user believing something is live that
  never left the building.

## 0.2.4
- Documented `regenerate_content` as the third thing to do with a pending feed
  card, alongside approve and reject — the same three the owner sees on the web.
  It rewrites a draft in place and takes `content_type` + `content_id`.
- Pointed at `available_actions[].args`, which the server now computes: neither
  the id nor the `SocialCopy` → `social_copy` conversion has to be derived by hand.
- `dismiss_feed_item` still works and is still documented, but is no longer one
  of the three offered choices.
- Fixed the version in `SKILL.md`, which had been stuck at 0.2.2 since 0.2.3
  bumped only `marketplace.json`. `scripts/bump-version.sh` now moves both.

## 0.2.3
- Added direct API guidance for posts, wallet, platforms, explicit delivery
  actions, and field-level content edits so agents can avoid an LLM turn for
  deterministic operations.

## 0.2.2
- Added the fast CMO Feed endpoint so agents can inspect pending review items
  without sending a CMO chat message.

## 0.2.1
- Added fast read-only API guidance for product counts, product lists, and CMO
  status so agents do not spend a CMO chat turn on simple facts.

## 0.2.0
- Positioning: sell **relief**, not output. The skill led with "batches of ad
  creatives" (a capability); nobody with a product wakes up wanting ad
  creatives — they wake up dreading the edit, the translation, and the daily
  post. Now matches the site's single source of truth: *you never have to make
  content again*.
- Named the two things that make that promise credible, neither of which the
  skill said before: the content **doesn't look like an ad**, and the CMO
  **has seen what your rivals are posting**.
- Dropped the hardcoded "30+ platforms" — the count drifts and contradicted
  the site ("every channel you've connected" is true and stays true).
- Declared `license: MIT` in the frontmatter (catalogs read it from there).

## 0.1.0
- Initial release: drive the AutoWhisper CMO from an agent — connect a
  product, generate content, approve, connect platforms, and publish via
  `/api/cmo/*` (message → poll → confirm).
