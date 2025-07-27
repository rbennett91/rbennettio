#!/bin/bash
set -e

# Be sure to fill out the environment variables in rbennettio/settings/app.env and source the file!

# Validate required environment variables
required_vars=("DB_PATH" "DB_BACKUP_FILENAME" "DB_BACKUP_S3_BUCKET")
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "Error: Required environment variable $var is not set" >&2
        exit 1
    fi
done

# Validate database exists and is readable
if [[ ! -f "$DB_PATH" ]]; then
    echo "Error: Database file $DB_PATH does not exist" >&2
    exit 1
fi

# Create secure temporary directory & cleanup on exit
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "Starting database backup on $(date)"
echo "Database: $DB_PATH"
echo "Backup destination: $DB_BACKUP_S3_BUCKET/$DB_BACKUP_FILENAME.gz"

# Create backup with error checking
echo "Creating database backup..."
if ! sqlite3 "$DB_PATH" ".backup $TEMP_DIR/$DB_BACKUP_FILENAME"; then
    echo "Error: Failed to create database backup" >&2
    exit 1
fi

# Verify backup was created and is not empty
if [[ ! -s "$TEMP_DIR/$DB_BACKUP_FILENAME" ]]; then
    echo "Error: Backup file is empty or was not created" >&2
    exit 1
fi

# Compress
echo "Compressing backup..."
gzip "$TEMP_DIR/$DB_BACKUP_FILENAME"

# Verify compression succeeded
if [[ ! -s "$TEMP_DIR/$DB_BACKUP_FILENAME.gz" ]]; then
    echo "Error: Compression failed" >&2
    exit 1
fi

# Upload to S3 with verification
echo "Uploading backup to S3..."
if ! aws s3 cp "$TEMP_DIR/$DB_BACKUP_FILENAME.gz" "$DB_BACKUP_S3_BUCKET/"; then
    echo "Error: Failed to upload backup to S3" >&2
    exit 1
fi

echo "Backup completed successfully on $(date)"
