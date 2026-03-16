# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

Add whatever helps you do your job. This is your cheat sheet.

### AgentMail
- Inbox: frodotheclaw@agentmail.to
- API key: stored in ~/.openclaw/openclaw.json under skills.agentmail.env.AGENTMAIL_API_KEY
- API base: https://api.agentmail.to/v0
- List unread: GET /inboxes/{inbox}/messages?limit=50 → filter labels contains "unread" + "received"
- Reply: POST /inboxes/{inbox}/messages/{url-encoded-message_id}/reply with {"text": "..."}
- Deduplicate by thread_id when replying to avoid double replies per thread
- ⚠️ CRITICAL: After replying, ALWAYS mark messages as read:
  PATCH /inboxes/{inbox}/messages/{url-encoded-message_id} with {"remove_labels": ["unread"]}
  Otherwise the same messages will be replied to on every reminder cycle!
- Auto-reply script: ~/workspace/agentmail_reply.py (handles dedup + mark-as-read correctly)
- Run for reminders: python3 ~/workspace/agentmail_reply.py
