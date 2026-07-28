# Changelog

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
