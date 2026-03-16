"""
Script: reply_unread_with_ponyal.py
Purpose: Connect to an IMAP mailbox, find unread inbound messages, and reply to each with the Russian single-word reply "Понял." using SMTP.

Usage: configure IMAP and SMTP credentials via environment variables or a .env file.

Environment variables used:
- AGENTMAIL_IMAP_HOST
- AGENTMAIL_IMAP_PORT (optional, default 993)
- AGENTMAIL_IMAP_USER
- AGENTMAIL_IMAP_PASS
- AGENTMAIL_SMTP_HOST
- AGENTMAIL_SMTP_PORT (optional, default 587)
- AGENTMAIL_SMTP_USER
- AGENTMAIL_SMTP_PASS
- AGENTMAIL_FROM (optional; defaults to AGENTMAIL_SMTP_USER)

Note: This script is intended to be run on a secure machine where credentials are stored safely. It does not persist credentials; for automation, use a system-managed secret store or a properly permissioned .env file.
"""

import os
import imaplib
import email
from email.header import decode_header, make_header
from email.message import EmailMessage
import smtplib
import ssl

IMAP_HOST = os.getenv('AGENTMAIL_IMAP_HOST')
IMAP_PORT = int(os.getenv('AGENTMAIL_IMAP_PORT', '993'))
IMAP_USER = os.getenv('AGENTMAIL_IMAP_USER')
IMAP_PASS = os.getenv('AGENTMAIL_IMAP_PASS')

SMTP_HOST = os.getenv('AGENTMAIL_SMTP_HOST')
SMTP_PORT = int(os.getenv('AGENTMAIL_SMTP_PORT', '587'))
SMTP_USER = os.getenv('AGENTMAIL_SMTP_USER')
SMTP_PASS = os.getenv('AGENTMAIL_SMTP_PASS')

FROM_ADDR = os.getenv('AGENTMAIL_FROM') or SMTP_USER
REPLY_TEXT = 'Понял.'

if not all([IMAP_HOST, IMAP_USER, IMAP_PASS, SMTP_HOST, SMTP_USER, SMTP_PASS]):
    raise SystemExit('Missing one or more required environment variables. See script header for details.')

def decode_mime_words(s):
    if not s:
        return ''
    try:
        return str(make_header(decode_header(s)))
    except Exception:
        return s


def find_unseen_and_reply():
    context = ssl.create_default_context()
    # Connect to IMAP
    with imaplib.IMAP4_SSL(IMAP_HOST, IMAP_PORT) as imap:
        imap.login(IMAP_USER, IMAP_PASS)
        imap.select('INBOX')
        status, data = imap.search(None, 'UNSEEN')
        if status != 'OK':
            print('IMAP search failed:', status)
            return
        ids = data[0].split()
        if not ids:
            print('No unread messages.')
            return

        # Prepare SMTP connection once
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as smtp:
            smtp.starttls(context=context)
            smtp.login(SMTP_USER, SMTP_PASS)

            for num in ids:
                typ, msg_data = imap.fetch(num, '(RFC822)')
                if typ != 'OK':
                    print('Failed to fetch message', num)
                    continue
                raw = msg_data[0][1]
                msg = email.message_from_bytes(raw)
                subject = decode_mime_words(msg.get('Subject'))
                from_hdr = decode_mime_words(msg.get('From'))
                # Parse sender address for reply-to
                reply_to = email.utils.parseaddr(msg.get('Reply-To') or msg.get('From'))[1]
                if not reply_to:
                    print('No sender address found for message', num)
                    imap.store(num, '+FLAGS', '\\Seen')
                    continue

                # Build reply
                reply = EmailMessage()
                reply['From'] = FROM_ADDR
                reply['To'] = reply_to
                reply['Subject'] = 'Re: ' + subject if subject else 'Re: '
                reply['In-Reply-To'] = msg.get('Message-ID') or ''
                reply['References'] = msg.get('Message-ID') or ''
                reply.set_content(REPLY_TEXT)

                try:
                    smtp.send_message(reply)
                    print(f'Replied to {reply_to} (message {num.decode()})')
                    # Mark original as Seen
                    imap.store(num, '+FLAGS', '\\Seen')
                except Exception as e:
                    print('Failed to send reply to', reply_to, 'error:', e)

        imap.logout()

if __name__ == '__main__':
    find_unseen_and_reply()
