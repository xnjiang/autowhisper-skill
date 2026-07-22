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
- `200 {"status":"pending","counts":{"pending":2,"approved":1},"feed_items":[{"id":1,"status":"pending","feedable":{"type":"SocialCopy","title":"...","product_name":"..."},"available_actions":[{"tool":"approve_feed_item","confirmation_required":false}]}]}`
- `401` invalid/missing token · `404` inaccessible workspace · `422` invalid status

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
