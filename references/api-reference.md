# AutoWhisper API Reference

Base: `https://autowhisper.xyz`  ·  Auth: `Authorization: Bearer <api_token>`

## Fast read-only endpoints

Use these for simple facts instead of `/api/cmo/message`; they are synchronous
and do not spend an LLM turn.

### GET /api/products/summary
Returns account-level product counts plus counts by active workspace.
- `200 {"account":{"workspaces_count":2,"active_products_count":12,"archived_products_count":1,"total_products_count":13},"current_workspace":{...},"workspaces":[...]}`
- `401` invalid/missing token

### GET /api/products
Lists products in active workspaces.
Query params: `workspace_id` (optional int), `include_archived` (optional
bool), `limit` (optional int).
- `200 {"scope":"account","count":12,"returned":12,"products":[{"id":1,"name":"...","product_type":"digital","workspace_name":"...","archived":false,"has_main_image":true}]}`
- `401` invalid/missing token · `404` inaccessible workspace

### GET /api/cmo/status
Returns a compact status snapshot: current workspace, product counts, feed
status counts, platform connection counts, wallet balance, and automation
settings.
- `200 {"products":{"active_count":12,"archived_count":1,"total_count":13},"feed":{"pending":2},"platforms":{"connected_count":4},"wallet":{"formatted_balance":"9 tokens"},"settings":{...}}`
- `401` invalid/missing token

### GET /api/cmo/feed
Lists CMO Feed items without a chat turn.
Query params: `status` (`pending` default, or `approved`/`rejected`/
`dismissed`/`executed`/`all`), `workspace_id` (optional int), `limit`
(optional int).
- `200 {"status":"pending","counts":{"pending":2,"approved":1},"feed_items":[{"id":1,"status":"pending","feedable":{"type":"SocialCopy","id":4,"title":"...","product_name":"..."},"available_actions":[{"tool":"approve_feed_item","args":{"feed_item_id":1},"confirmation_required":true},{"tool":"regenerate_content","args":{"content_type":"social_copy","content_id":4},"confirmation_required":true}]}]}`
- `401` invalid/missing token · `404` inaccessible workspace · `422` invalid status

Account-wide by default; `workspace_id` narrows it. Note the two ids on each row:
`id` is the feed item (for the `actions` endpoint), `feedable.id` is the content
(for the content `PATCH`). See the warning under that endpoint.

### GET /api/posts
Lists the delivery queue across **all active workspaces** (same scope as
`/api/cmo/feed`); pass `workspace_id` to narrow to one.
Query params: `status` (optional `draft`/`scheduled`/`publishing`/`published`/
`failed`), `workspace_id` (optional int), `limit` (optional int).
- `200 {"scope":"account","workspace":null,"posts":[{"id":9,"status":"scheduled","scheduled_at":"...","workspace":{"id":1,"name":"..."},"platform":{"type":"linkedin"},"content":{"type":"SocialCopy","id":4,"title":"..."},"failure":null}]}`
- `404` inaccessible workspace · `422` invalid status

**Failed posts** carry a `failure` block — read it before deciding what to do:
- `{"reason":"<platform's real message>","needs_reconnect":false,"retry_count":1}`
- `needs_reconnect: true` → only the human can fix it (re-run OAuth);
  `retry_post` will keep failing. Otherwise `retry_post` is worth one attempt; if
  `reason` points at the content itself, edit it first, then retry.

### GET /api/wallet
Returns the token owner's available credits.
- `200 {"balance":9.0,"formatted_balance":"9 credits","currency":"credits"}`

### GET /api/platforms
Lists connected destinations and connection health across **all active
workspaces**, so it can never disagree with `/api/cmo/status`'s counts. Pass
`workspace_id` to narrow to one. Each row names its workspace.
Query params: `workspace_id` (optional int).
- `200 {"scope":"account","workspace":null,"platforms":[{"id":2,"workspace":{"id":1,"name":"..."},"type":"linkedin","connected":true,"needs_reconnect":false,"auto_publishable":true}]}`
- `404` inaccessible workspace

## Direct deterministic actions

### POST /api/cmo/actions/:tool
Run an explicit action without an LLM chat turn. Supported `:tool` values:
`approve_feed_item`, `reject_feed_item`, `dismiss_feed_item`,
`publish_content`, `regenerate_content`, `reschedule_post`, `retry_post`,
`mark_as_published`.
Form params are the corresponding ids (`feed_item_id` or `post_id`), plus
`scheduled_at` for rescheduling and optional `reason` for rejection.

`regenerate_content` is the exception: it addresses the CONTENT, not the card,
so it takes `content_type` (snake_case: `social_copy` / `lookbook` /
`feature_poster` / `idea`) and `content_id` — optionally `reference_url` and
`template_code`. It rewrites the draft in place, keeping the same record id,
and is the same action as the Revise button on the web feed card. Do not reach
for `PATCH /api/cmo/content/...` for this: that endpoint overwrites the fields
you give it verbatim and regenerates nothing.

It spends credits, so it always returns `202 confirmation_required` on this
endpoint — confirm it like any other. That is deliberate and unconditional: the
owner should see what a rewrite costs before it runs, and it must not depend on
what they last happened to type in the web chat.

High-impact actions still obey CMO policy and return a confirmation instead of
executing immediately:
- `202 {"confirmation_required":true,"message_id":123}` → call
  `POST /api/cmo/confirm` with that id.
- `200 {"success":true,"message":"..."}` → action completed.

### PATCH /api/cmo/content/:content_type/:content_id
Edits exact fields without a generation run or credit charge. `content_type` is
one of `social_copy`, `lookbook`, `feature_poster`, `idea`.

⚠️ `:content_id` is `feed_items[].feedable.id`, **not** `feed_items[].id`, and
`:content_type` is the snake_case form of `feedable.type` (`SocialCopy` →
`social_copy`). Passing the feed item id is the usual cause of a `422`
"not found". Works on content in any of the token owner's active workspaces.

Form params: any of `title`, `body`, `hook`, `cta`, `tone`, `keywords[]`, and
optional `workspace_id`.
- `200 {"success":true,"updated_fields":["title","content"],"message":"..."}`
- `422` invalid or inaccessible content/fields

## POST /api/cmo/message
Send the CMO an instruction. Async — returns immediately.
Form params: `message` (required), `product_id` (optional int),
`workspace_id` (optional int).
- `202 {"status":"accepted","message_id":123}`
- `401` invalid/missing token · `422` blank message

## GET /api/cmo/messages/:id
Poll the turn started by the given user `message_id`.
- `200 {"done":false,"messages":[]}` — still working
- `200 {"done":true,"messages":[{"message_id":9,"role":"assistant","content":"...","message_kind":null,"pending_action":null}]}`
- A message with `"message_kind":"confirm_required"` and a `pending_action`
  `{ "tool":"...", "args":{...} }` requires a confirm.
- A message may include `"actions":[{ "label":"...", "url":"https://cdn.autowhisper.xyz/...", "style":"secondary" }]`
  — clickable cards the CMO surfaces (content **media links**, connect links).
  The reply `content` never inlines raw URLs, so read `actions[].url` when you
  need the image/video URL of a piece of content (ask e.g. "give me the image
  link for X" / "list my recent content with images").
- `404` unknown id / not yours

Poll every ~3s; a turn typically completes in seconds (generation of media
runs in the background and lands in the user's Feed — `done:true` means the
CMO's reply is ready, not that a video finished rendering).

## POST /api/cmo/confirm
Resolve a `confirm_required` bubble.
Form params: `message_id`, `decision` (`yes`|`no`).
- `200` resolved · `404` unknown · `422` not a confirm bubble · `410` already resolved

## Notes
- Rate limited; back off on `429`.
- New accounts get free credits; generation consumes credits.
- Publishing requires at least one connected platform (one-time OAuth).
