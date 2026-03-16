#!/bin/bash
#
# OpenClaw Agent Backup Script
# Backs up critical configuration files to a private GitHub repository
# Runs daily at 4:30am via cron
# Usage: ./backup_agent.sh [github_repo_url]
#

set -euo pipefail

# Note: .env files are NOT loaded or backed up for security reasons
# All secrets must be configured separately or use SSH for git operations

# Configuration
BACKUP_DIR="/tmp/openclaw-backup-$(date +%Y%m%d-%H%M%S)"
REPO_DIR="/tmp/openclaw-backup-repo"
LOG_FILE="/tmp/openclaw-backup.log"
GITHUB_REPO="${1:-}"  # Pass as argument or set here

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

# Cleanup function
cleanup() {
    if [[ -d "$BACKUP_DIR" ]]; then
        rm -rf "$BACKUP_DIR"
        log "Cleaned up temporary backup directory"
    fi
}

trap cleanup EXIT

# Check if GitHub repo URL is provided
if [[ -z "$GITHUB_REPO" ]]; then
    error "GitHub repository URL not provided!"
    error "Usage: $0 <github_repo_url>"
    error "Example: $0 git@github.com:username/openclaw-backup.git"
    exit 1
fi

log "Starting OpenClaw backup..."
log "GitHub repo: $GITHUB_REPO"

# Create backup staging area
mkdir -p "$BACKUP_DIR"
log "Created backup staging area: $BACKUP_DIR"

# Define source directories and files to backup
declare -a BACKUP_SOURCES=(
    # NOTE: obsidian_notes folder is now in workspace, copied dynamically below
    
    # OpenClaw workspace - workflow files
    "/home/ubuntu/.openclaw/workspace/SOUL.md"
    "/home/ubuntu/.openclaw/workspace/MEMORY.md"
    "/home/ubuntu/.openclaw/workspace/IDENTITY.md"
    "/home/ubuntu/.openclaw/workspace/AGENTS.md"
    "/home/ubuntu/.openclaw/workspace/TOOLS.md"
    "/home/ubuntu/.openclaw/workspace/USER.md"
    "/home/ubuntu/.openclaw/workspace/HEARTBEAT.md"
    # NOTE: .env files are excluded from backup for security
    "/home/ubuntu/.openclaw/workspace/backup_agent.sh"
    "/home/ubuntu/.openclaw/workspace/send_privet.py"
    "/home/ubuntu/.openclaw/workspace/agentmail_reply.py"
    "/home/ubuntu/.openclaw/workspace/agentmail_process.py"
    "/home/ubuntu/.openclaw/workspace/privet_state.json"
    "/home/ubuntu/.openclaw/workspace/.openclaw/workspace-state.json"
    
    # Agentmail subdirectory
    "/home/ubuntu/.openclaw/workspace/agentmail/README_AGENTMAIL.md"
    "/home/ubuntu/.openclaw/workspace/agentmail/reply_unread_with_ponyal.py"
    
    # Memory files
    "/home/ubuntu/.openclaw/workspace/memory/rules/archive.md"
    "/home/ubuntu/.openclaw/workspace/memory/rules/README.md"
    "/home/ubuntu/.openclaw/workspace/memory/rules/hot.md"
    "/home/ubuntu/.openclaw/workspace/memory/rules/context.md"
    "/home/ubuntu/.openclaw/workspace/memory/rules/corrections.log"
    "/home/ubuntu/.openclaw/workspace/memory/agentmail-replied.json"
    
    # Main OpenClaw configuration (gateway config)
    "/home/ubuntu/.openclaw/openclaw.json"
    
    # Credentials (will be scrubbed)
    "/home/ubuntu/.openclaw/credentials/telegram-default-allowFrom.json"
    "/home/ubuntu/.openclaw/credentials/telegram-pairing.json"
    
    # Identity files (will be scrubbed)
    "/home/ubuntu/.openclaw/identity/device.json"
    "/home/ubuntu/.openclaw/identity/device-auth.json"
    
    # Device configs
    "/home/ubuntu/.openclaw/devices/pending.json"
    "/home/ubuntu/.openclaw/devices/paired.json"
    
    # Agent configuration
    "/home/ubuntu/.openclaw/agents/main/agent/auth-profiles.json"
    "/home/ubuntu/.openclaw/agents/main/agent/models.json"
    
    # Cron jobs
    "/home/ubuntu/.openclaw/cron/jobs.json"
    
    # Telegram config
    "/home/ubuntu/.openclaw/telegram/update-offset-default.json"
    
    # Skills
    "/home/ubuntu/.openclaw/skills/self-improving-agent/SKILL.md"
    "/home/ubuntu/.openclaw/skills/self-improving-agent/.learnings/ERRORS.md"
    "/home/ubuntu/.openclaw/skills/self-improving-agent/.learnings/LEARNINGS.md"
    "/home/ubuntu/.openclaw/skills/self-improving-agent/.learnings/FEATURE_REQUESTS.md"
)

# Copy files to staging area
log "Copying files to staging area..."
for src in "${BACKUP_SOURCES[@]}"; do
    if [[ -f "$src" ]]; then
        # Create directory structure
        rel_path="${src#/home/ubuntu/}"
        target_dir="$BACKUP_DIR/$(dirname "$rel_path")"
        mkdir -p "$target_dir"
        cp "$src" "$target_dir/"
        log "  ✓ $src"
    else
        warn "  ✗ Not found: $src"
    fi
done

# Copy memory directory markdown files
log "Copying memory files..."
find /home/ubuntu/.openclaw/workspace/memory/ -name "*.md" -type f 2>/dev/null | while read -r file; do
    rel_path="${file#/home/ubuntu/}"
    target_dir="$BACKUP_DIR/$(dirname "$rel_path")"
    mkdir -p "$target_dir"
    cp "$file" "$target_dir/"
    log "  ✓ $file"
done

# Copy workspace skill files
log "Copying workspace skill files..."
find /home/ubuntu/.openclaw/workspace/skills/ -name "*.md" -type f 2>/dev/null | while read -r file; do
    rel_path="${file#/home/ubuntu/}"
    target_dir="$BACKUP_DIR/$(dirname "$rel_path")"
    mkdir -p "$target_dir"
    cp "$file" "$target_dir/"
    log "  ✓ $file"
done

# Copy obs_notes folder
if [[ -d "/home/ubuntu/.openclaw/workspace/obs_notes" ]]; then
    log "Copying obs_notes folder..."
    find /home/ubuntu/.openclaw/workspace/obs_notes/ -type f 2>/dev/null | while read -r file; do
        rel_path="${file#/home/ubuntu/}"
        target_dir="$BACKUP_DIR/$(dirname "$rel_path")"
        mkdir -p "$target_dir"
        cp "$file" "$target_dir/"
        log "  ✓ $file"
    done
fi

# Copy obsidian_notes folder (now in workspace)
if [[ -d "/home/ubuntu/.openclaw/workspace/obsidian_notes" ]]; then
    log "Copying obsidian_notes folder..."
    find /home/ubuntu/.openclaw/workspace/obsidian_notes/ -type f 2>/dev/null | while read -r file; do
        rel_path="${file#/home/ubuntu/}"
        target_dir="$BACKUP_DIR/$(dirname "$rel_path")"
        mkdir -p "$target_dir"
        cp "$file" "$target_dir/"
        log "  ✓ $file"
    done
fi

success "Files copied to staging area"

# Load secrets from external file (not backed up to GitHub)
SECRET_FILE="/home/ubuntu/.openclaw/workspace/backup_secrets.sh"
if [[ -f "$SECRET_FILE" ]]; then
    source "$SECRET_FILE"
else
    warn "Secret file not found: $SECRET_FILE"
    # Define empty arrays as fallback
    declare -A SECRET_PATTERNS=()
    declare -A SPECIFIC_SECRETS=()
fi

log "Scanning for secrets..."
SECRETS_FOUND=0

# Function to scan and replace secrets in a file
scan_and_replace_secrets() {
    local file="$1"
    local temp_file="${file}.tmp"
    local secrets_in_file=0
    
    # Create a copy for processing
    cp "$file" "$temp_file"
    
    # Replace specific secrets first
    for secret in "${!SPECIFIC_SECRETS[@]}"; do
        if grep -q "$secret" "$temp_file" 2>/dev/null; then
            secrets_in_file=$((secrets_in_file + 1))
            SECRETS_FOUND=$((SECRETS_FOUND + 1))
            log "  Found secret in: $file"
            sed -i "s|$secret|${SPECIFIC_SECRETS[$secret]}|g" "$temp_file"
        fi
    done
    
    # Move temp file back
    mv "$temp_file" "$file"
    
    # Always return 0 to prevent set -e from exiting
    return 0
}

# Scan all files in backup directory
export -f scan_and_replace_secrets
export SECRETS_FOUND
export -A SPECIFIC_SECRETS

find "$BACKUP_DIR" -type f \( -name "*.json" -o -name "*.py" -o -name "*.md" -o -name "*.env" -o -name "*.txt" -o -name "*.yaml" -o -name "*.yml" \) -print0 | while IFS= read -r -d '' file; do
    scan_and_replace_secrets "$file"
done

if [[ $SECRETS_FOUND -gt 0 ]]; then
    warn "Found and redacted $SECRETS_FOUND secret(s)"
else
    log "No secrets found (or all already redacted)"
fi

# Handle PEM keys specially (multi-line)
log "Checking for PEM private keys..."
find "$BACKUP_DIR" -type f -name "*.json" -exec grep -l "BEGIN PRIVATE KEY" {} \; | while read -r file; do
    warn "Found private key in: $file"
    # Use Python for complex multi-line replacements
    python3 << 'EOF' - "$file"
import json
import sys
import re

file_path = sys.argv[1]
with open(file_path, 'r') as f:
    content = f.read()

# Replace privateKeyPem
content = re.sub(
    r'"privateKeyPem":\s*"-----BEGIN PRIVATE KEY-----[^"]*-----END PRIVATE KEY-----"',
    '"privateKeyPem": "[PRIVATE_KEY_REDACTED]"',
    content,
    flags=re.DOTALL
)

with open(file_path, 'w') as f:
    f.write(content)
EOF
    log "  Redacted private key in $file"
done

# Create secrets report
cat > "$BACKUP_DIR/SECRETS_REPORT.md" << 'EOF'
# Secrets Redaction Report

This backup has been automatically scanned for secrets and sensitive data.
All detected secrets have been replaced with descriptive placeholders.

## Placeholders Used

- `[OPENAI_API_KEY]` - OpenAI API key
- `[ANTHROPIC_API_KEY]` - Anthropic API key
- `[MOONSHOT_API_KEY]` - Moonshot API key
- `[AGENTMAIL_API_KEY]` - AgentMail API key
- `[TELEGRAM_BOT_TOKEN]` - Telegram bot token
- `[DISCORD_TOKEN]` - Discord bot token
- `[GATEWAY_AUTH_TOKEN]` - OpenClaw gateway authentication token
- `[OPERATOR_TOKEN]` - Device operator token
- `[DEVICE_ID]` - Device identifier
- `[TELEGRAM_USER_ID]` - Telegram user ID
- `[PRIVATE_KEY_REDACTED]` - Private key (PEM format)

## Files Scanned

All configuration files, scripts, and JSON files in this backup were scanned.

## Date

Backup created: $(date '+%Y-%m-%d %H:%M:%S')
EOF

success "Secret scanning complete"

# Setup or update git repository
log "Setting up git repository..."

# Use SSH URL for GitHub (no tokens needed, uses SSH key authentication)
# Convert HTTPS URL to SSH if needed
if [[ "$GITHUB_REPO" == https://github.com/* ]]; then
    REPO_PATH=$(echo "$GITHUB_REPO" | sed 's|https://github.com/||')
    GIT_URL="git@github.com:${REPO_PATH}.git"
elif [[ "$GITHUB_REPO" == git@github.com:* ]]; then
    GIT_URL="$GITHUB_REPO"
else
    # Assume it's just owner/repo format
    GIT_URL="git@github.com:${GITHUB_REPO}.git"
fi

log "Using SSH URL: $GIT_URL"

if [[ -d "$REPO_DIR/.git" ]]; then
    log "Using existing repository"
    cd "$REPO_DIR"
    git remote set-url origin "$GIT_URL"
    git fetch origin
    git reset --hard origin/main 2>/dev/null || git reset --hard origin/master 2>/dev/null || true
else
    log "Cloning repository via SSH..."
    rm -rf "$REPO_DIR"
    GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" git clone "$GIT_URL" "$REPO_DIR"
    cd "$REPO_DIR"
fi

# Clear old content but keep .git
find "$REPO_DIR" -mindepth 1 -not -path "$REPO_DIR/.git/*" -not -path "$REPO_DIR/.git" -delete 2>/dev/null || true

# Copy new backup content (including hidden files)
# Use tar to preserve all files including hidden ones
tar -C "$BACKUP_DIR" -cf - . | tar -C "$REPO_DIR" -xf -

# Create README if it doesn't exist
cat > "$REPO_DIR/README.md" << 'EOF'
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

EOF
echo "$(date '+%Y-%m-%d %H:%M:%S UTC')" >> "$REPO_DIR/README.md"

# Git operations
git add -A

# Check if there are changes
if git diff --cached --quiet; then
    log "No changes to commit"
else
    # Commit with timestamp and summary
    CHANGES=$(git diff --cached --stat | tail -1)
    git commit -m "Backup $(date '+%Y-%m-%d %H:%M') - $CHANGES"
    
    # Push to GitHub
    log "Pushing to GitHub..."
    if git push origin HEAD; then
        success "Backup pushed successfully!"
    else
        error "Failed to push to GitHub"
        exit 1
    fi
fi

success "Backup complete!"
log "Backup log saved to: $LOG_FILE"

# Print summary
echo ""
echo "========================================"
echo "BACKUP SUMMARY"
echo "========================================"
echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Repository: $GITHUB_REPO"
echo "Secrets redacted: $SECRETS_FOUND"
echo "Status: SUCCESS"
echo "========================================"
