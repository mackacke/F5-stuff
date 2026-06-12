# Adds cron configuration directories to UCS backups.
# Remounts /usr RW, updates configsync cs.dat, and restores /usr RO.
# Includes progress output for easier troubleshooting.
#!/bin/bash

set -e

CS_FILE="/usr/libdata/configsync/cs.dat"

echo "[1/6] Starting script..."

echo "[2/6] Remounting /usr as read-write..."
mount -o remount,rw /usr

echo "      Verifying /usr is RW..."
if findmnt -no OPTIONS /usr | grep -qw rw; then
    echo "      OK: /usr is now READ-WRITE"
else
    echo "      ERROR: /usr is NOT read-write. Aborting."
    exit 1
fi

echo "[3/6] Checking for existing cron backup entries..."
if grep -Eq 'save\.(13000|13001|13002)\.' "$CS_FILE"; then
    echo "      Entries already exist. No changes will be made."
    CHANGED=0
else
    echo "      No existing entries found. Adding block..."

    cat >> "$CS_FILE" <<'EOF'

# backup cronjobs
save.13000.dir = /var/spool/cron
save.13001.file = /etc/crontab
save.13002.dir = /etc/cron.d
EOF

    echo "      Entries successfully added."
    CHANGED=1
fi

echo "[4/6] Remounting /usr as read-only..."
mount -o remount,ro /usr

echo "      Verifying /usr is RO..."
if findmnt -no OPTIONS /usr | grep -qw ro; then
    echo "      OK: /usr is now READ-ONLY"
else
    echo "      WARNING: /usr is NOT read-only"
fi

echo "[5/6] Verifying mount status..."
echo -n "      /usr options: "
findmnt -no OPTIONS /usr

echo "[6/6] Final result:"
if [ "$CHANGED" = "1" ]; then
    echo "      CONFIG UPDATED"
else
    echo "      NO CHANGES NEEDED"
fi

echo "Done."
