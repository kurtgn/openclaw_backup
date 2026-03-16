# OpenClaw Agent Backup

This repository contains automated backups of the OpenClaw agent configuration.

## Contents

- `obsidian_notes/my/` - Personality and memory files (SOUL.md, MEMORY.md, etc.)
- `.openclaw/workspace/` - Workflow files and scripts
- `.openclaw/` - Configuration files, credentials (redacted), and agent settings

## Security

⚠️ **All secrets have been redacted** from these files before committing.
Sensitive values are replaced with placeholders like `[API_KEY_NAME]`.

## Backup Schedule

This backup runs daily at 4:30 AM UTC via cron job.

## Restoration

To restore from this backup:
1. Clone this repository
2. Copy files to their original locations in `/home/ubuntu/`
3. Re-add your actual secrets (API keys, tokens) from your secure storage

## Last Backup

2026-03-16 16:42:47 UTC
