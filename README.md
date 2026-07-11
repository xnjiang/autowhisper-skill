# AutoWhisper Skill

**Audience: Human (project overview)**

A marketing department for your agent. Connect a product and AutoWhisper turns
it into batches of ready-to-run ad creatives, keeps every channel alive across
30+ platforms, and tells you which creative to fund — driven in natural
language from Claude Code, Cursor, n8n, or any MCP-capable agent.
(Honest scope: posting ≠ traffic — reach comes from your paid campaigns.)

## Quick Start

### 1. Install skill

```bash
npx skills add xnjiang/autowhisper-skill
```
Or tell your AI: `Install skill from https://autowhisper.xyz/skill`

### 2. Get your token

Sign up at https://autowhisper.xyz (new accounts get free credits), open
**Settings → Connect your agent**, and copy your API token.

### 3. Configure token

```bash
mkdir -p ~/.config/autowhisper
echo '{"api_token": "your_token_here"}' > ~/.config/autowhisper/credentials.json
```

### 4. One-time: connect a platform to publish

Publishing needs a connected social account. Ask your AI to
`connect my tiktok` (OAuth platforms return a link you click once; Chinese
platforms connect with your handle). After that, your agent can publish on
its own.

### 5. Use it

```
"Add my product https://mystore.com/widget and start the CMO"
"Generate a UGC video for my product"
"Publish the approved content"
"What did the CMO do — show me analytics"
```

## How it works

Your agent talks to AutoWhisper's CMO (the same brain as the web dashboard
chat) over a small HTTP API. See `SKILL.md` (for agents) and
`references/api-reference.md` (endpoints).

## License

MIT — see `LICENSE`.
