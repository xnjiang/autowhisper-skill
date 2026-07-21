# AutoWhisper API Reference

Base: `https://autowhisper.xyz`  ·  Auth: `Authorization: Bearer <api_token>`

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
