#!/usr/bin/env python3
import os, json, subprocess, urllib.parse, sys, datetime
API_KEY = os.environ.get('AGENTMAIL_API_KEY') or '[AGENTMAIL_API_KEY]'
INBOX = 'frodotheclaw@agentmail.to'
REPLIED_FILE = '/home/ubuntu/.openclaw/workspace/memory/agentmail-replied.json'

def api(method, path, payload=None):
    args = [
        'curl','-s','-X',method,
        f'https://api.agentmail.to/v0{path}',
        '-H', f'Authorization: Bearer {API_KEY}',
        '-H', 'Content-Type: application/json'
    ]
    if payload is not None:
        args += ['-d', json.dumps(payload)]
    r = subprocess.run(args, capture_output=True, text=True)
    try:
        return json.loads(r.stdout)
    except Exception:
        return {'error': r.stdout}

# load replied
try:
    replied_db = json.load(open(REPLIED_FILE))
    replied_ids = {r['message_id'] for r in replied_db.get('replied', [])}
except Exception:
    replied_db = {'replied': []}
    replied_ids = set()

# list messages
data = api('GET', f'/inboxes/{urllib.parse.quote(INBOX, safe="")}/messages?limit=200')
msgs = data.get('messages', [])
unread = [m for m in msgs if 'unread' in (m.get('labels') or []) and 'received' in (m.get('labels') or [])]
seen_threads = {}
all_unread_ids = []
for m in unread:
    tid = m.get('thread_id')
    all_unread_ids.append(m.get('message_id'))
    # keep most recent per thread (API returns latest first often)
    if tid not in seen_threads:
        seen_threads[tid] = m

to_reply = [m for m in seen_threads.values() if m.get('message_id') not in replied_ids]

out = {'checked': len(msgs), 'unread_total': len(unread), 'to_reply': []}
if not to_reply:
    print(json.dumps(out))
    sys.exit(0)

for m in to_reply:
    msg_id = m['message_id']
    enc = urllib.parse.quote(msg_id, safe='')
    sender = m.get('from')
    subject = m.get('subject') or ''
    text = m.get('text') or ''
    # simple human reply template
    reply = f"Здравствуйте! Спасибо за сообщение. Я получил(а) ваше письмо: \"{subject}\". Я посмотрю и вернусь с ответом в ближайшее время. —Sam"
    resp = api('POST', f"/inboxes/{urllib.parse.quote(INBOX, safe='')}/messages/{enc}/reply", {'text': reply})
    success = 'message_id' in resp or 'id' in resp
    record = {
        'message_id': msg_id,
        'thread_id': m.get('thread_id',''),
        'from': sender,
        'subject': subject,
        'replied_at': datetime.datetime.utcnow().isoformat()+'Z',
        'note': reply if success else f'failed: {str(resp)[:200]}'
    }
    out['to_reply'].append({'record': record, 'success': success, 'orig_text': text})
    if success:
        replied_db.setdefault('replied',[]).append(record)

# mark all unread as read
for mid in all_unread_ids:
    api('PATCH', f"/inboxes/{urllib.parse.quote(INBOX, safe='')}/messages/{urllib.parse.quote(mid, safe='')}", {'remove_labels':['unread']})

# save replied_db
with open(REPLIED_FILE,'w') as f:
    json.dump(replied_db, f, indent=2, ensure_ascii=False)

print(json.dumps(out, ensure_ascii=False))
