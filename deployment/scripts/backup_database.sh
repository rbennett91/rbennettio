#!/bin/bash
set -e  # Exit on any error

# Be sure to fill out the environment variables in rbennettio/settings/app.env and source the file!
# You'll need the following environment variables:
# DB_PATH: the full path to the django sqlite db
# DB_BACKUP_FILENAME: the name of the sqlite3 backup file
# DB_BACKUP_S3_BUCKET: the full s3 path where the backup file will be stored

# This script can be scheduled via cron:
# crontab -e
# 0 5 * * * source </path/to/app.env> && </path/to/backup_database.sh>

TEMP_DIR="/tmp"

echo "Starting database backup at $(date)"

# Create backup
sqlite3 "$DB_PATH" ".backup $TEMP_DIR/${DB_BACKUP_FILENAME}"

# Compress
gzip "$TEMP_DIR/${DB_BACKUP_FILENAME}"

# Upload to S3
aws s3 cp "$TEMP_DIR/${DB_BACKUP_FILENAME}.gz" "$DB_BACKUP_S3_BUCKET"

# Cleanup
rm "$TEMP_DIR/${DB_BACKUP_FILENAME}.gz"

echo "Backup completed successfully at $(date)"
