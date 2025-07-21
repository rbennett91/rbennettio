#!/bin/bash
set -e

# Be sure to fill out the environment variables in rbennettio/settings/app.env and source the file!

echo "Restoring database backup at $(date)"

# Download the backup:
aws s3 cp $DB_BACKUP_S3_BUCKET/rbennettio.sqlite3.bak.gz .

# Unzip the backup:
gunzip rbennettio.sqlite3.bak.gz

#Move the backup:
mv rbennettio.sqlite3.bak $DB_PATH

echo "Backup restored at $(date)"
