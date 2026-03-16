# MEMORY.md — Долгосрочная память Sam

## AgentMail — правила работы с почтой

- **Ящик:** frodotheclaw@agentmail.to
- **API key:** хранится в openclaw.json (skills.entries.agentmail.env.AGENTMAIL_API_KEY)
- **SDK:** `pip install agentmail --break-system-packages` (уже установлен)
- **Cron:** проверка каждые 5 минут (job id: 57d6a913-f0f0-4ad3-aabc-fda95aefa009)

### Инструкция от Misha (2026-03-12):
- На входящие письма **отвечать по существу** — не "Понял.", а нормальный человеческий ответ
- Перед ответом читать текст письма и контекст треда
- После ответа записывать message_id в `memory/agentmail-replied.json`
- При проверке сверяться с этим файлом — не отвечать дважды на одно письмо
- Если письмо без контекста или непонятно что ответить — спросить Мишу
- **После каждого ответа** отправлять Мише уведомление в Telegram через `message` tool (только основная сессия — субагенты не могут отправлять в Telegram!)
  Формат уведомления:
  ```
  📬 Ответил на письмо от [Имя] ([адрес])
  Тема: [тема]
  
  ✉️ Письмо:
  [текст письма]
  
  💬 Мой ответ:
  [текст ответа]
  ```
- Cron-задача проверки почты должна использовать `sessionTarget: "main"`, не "isolated"

### Пример кода для проверки и ответа:
```python
from agentmail import AgentMail
import json, os

API_KEY = os.environ.get('AGENTMAIL_API_KEY', '[AGENTMAIL_API_KEY]')
INBOX = 'frodotheclaw@agentmail.to'
REPLIED_FILE = '/home/ubuntu/.openclaw/workspace/memory/agentmail-replied.json'

c = AgentMail(api_key=API_KEY)

# Загрузить уже отвеченные
try:
    replied_ids = {r['message_id'] for r in json.load(open(REPLIED_FILE))['replied']}
except:
    replied_ids = set()

threads = c.threads.list()
for t in (threads.threads or []):
    thread = c.threads.get(thread_id=t.thread_id)
    msgs = thread.messages or []
    last = msgs[-1] if msgs else None
    if last and 'received' in (last.labels or []) and last.message_id not in replied_ids:
        # Прочитать текст, придумать ответ, отправить
        pass  # c.inboxes.messages.send(INBOX, to=..., subject=..., text=...)
```
