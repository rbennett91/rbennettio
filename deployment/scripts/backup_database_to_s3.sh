#!/bin/bash
set -e

# Be sure to fill out the environment variables in rbennettio/settings/app.env and source the file!

TEMP_DIR="/tmp"

echo "Starting database backup at $(date)"

# Create backup
sqlite3 "$DB_PATH" ".backup $TEMP_DIR/$DB_BACKUP_FILENAME"

# Compress
gzip "$TEMP_DIR/$DB_BACKUP_FILENAME"

# Upload to S3
aws s3 cp "$TEMP_DIR/$DB_BACKUP_FILENAME.gz" "$DB_BACKUP_S3_BUCKET/"

# Cleanup
rm "$TEMP_DIR/$DB_BACKUP_FILENAME.gz"

echo "Backup completed successfully at $(date)"
