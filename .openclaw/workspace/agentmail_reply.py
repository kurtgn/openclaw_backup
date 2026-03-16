#!/usr/bin/env python3
"""
AgentMail auto-reply script.
- Finds all unread received messages in frodotheclaw@agentmail.to
- Sends "Понял." reply to the most recent message per thread
- Marks each processed message as read (removes 'unread' label)
- Safe to run repeatedly (idempotent via unread label check)

Usage: python3 agentmail_reply.py
"""
import json
import subprocess
import urllib.parse
import sys

API_KEY = "[AGENTMAIL_API_KEY]"
INBOX = "frodotheclaw@agentmail.to"
REPLY_TEXT = "Понял."


def api(method, path, payload=None):
    args = [
        "curl", "-s", "-X", method,
        f"https://api.agentmail.to/v0{path}",
        "-H", f"Authorization: Bearer {API_KEY}",
        "-H", "Content-Type: application/json",
    ]
    if payload:
        args += ["-d", json.dumps(payload)]
    r = subprocess.run(args, capture_output=True, text=True)
    return json.loads(r.stdout)


def run():
    data = api("GET", f"/inboxes/{INBOX}/messages?limit=50")
    msgs = data.get("messages", [])
    unread = [m for m in msgs if "unread" in m.get("labels", []) and "received" in m.get("labels", [])]

    # Deduplicate: reply once per thread (most recent message per thread)
    seen_threads = {}
    all_unread_ids = []
    for m in unread:
        tid = m["thread_id"]
        all_unread_ids.append(m["message_id"])
        if tid not in seen_threads:
            seen_threads[tid] = m

    to_reply = list(seen_threads.values())
    print(f"Unread messages: {len(unread)}, unique threads: {len(to_reply)}")

    if not to_reply:
        print("Nothing to do.")
        return

    for m in to_reply:
        msg_id = m["message_id"]
        encoded_id = urllib.parse.quote(msg_id, safe="")
        subject = m.get("subject", "(no subject)")
        sender = m["from"]

        # Send reply
        resp = api("POST", f"/inboxes/{INBOX}/messages/{encoded_id}/reply", {"text": REPLY_TEXT})
        if "message_id" in resp or "id" in resp:
            print(f"✓ Replied to {sender} | {subject}")
        else:
            print(f"✗ Reply failed for {sender} | {subject}: {str(resp)[:200]}", file=sys.stderr)

    # Mark ALL unread received messages as read (not just the one we replied to per thread)
    for msg_id in all_unread_ids:
        encoded_id = urllib.parse.quote(msg_id, safe="")
        api("PATCH", f"/inboxes/{INBOX}/messages/{encoded_id}", {"remove_labels": ["unread"]})
    print(f"Marked {len(all_unread_ids)} messages as read.")


if __name__ == "__main__":
    run()
