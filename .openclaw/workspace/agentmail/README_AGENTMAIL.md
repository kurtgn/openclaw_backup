AgentMail auto-reply helper

Purpose
- This folder contains a script (reply_unread_with_ponyal.py) that connects to an IMAP mailbox, finds unread messages, and replies "Понял." to each sender via SMTP.

Security & Usage
- Supply credentials as environment variables (see script header). Do NOT commit credentials to version control.
- Recommended: store secrets in a system secret manager or a .env file readable only by the service user (chmod 600).

Run manually
1) Install dependencies: the script uses only Python standard library (3.8+).
2) Export environment variables, for example:
   export AGENTMAIL_IMAP_HOST=imap.example.com
   export AGENTMAIL_IMAP_USER=frodotheclaw@agentmail.to
   export AGENTMAIL_IMAP_PASS=REPLACE
   export AGENTMAIL_SMTP_HOST=smtp.example.com
   export AGENTMAIL_SMTP_USER=frodotheclaw@agentmail.to
   export AGENTMAIL_SMTP_PASS=REPLACE
3) Run: python3 reply_unread_with_ponyal.py

Automate (cron)
- Add a cron entry for the service user to run every 5 minutes, e.g.:
  */5 * * * * /usr/bin/env bash -lc 'cd /home/ubuntu/.openclaw/workspace/agentmail && /usr/bin/python3 reply_unread_with_ponyal.py'

Notes
- The script marks messages as Seen after replying to avoid duplicate replies.
- It respects Reply-To when present.
- If you prefer replies to be threaded, ensure Message-IDs and References are handled by your mail server; the script sets In-Reply-To and References when the original Message-ID is present.
- If you want me to deploy and run this inside the workspace (or set up a cron job here), provide IMAP/SMTP credentials and state whether I may store them in workspace files or only use them temporarily. I will then connect and run as requested.
