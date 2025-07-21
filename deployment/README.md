# Production Deployment

## Infrastructure
TBD - describe infrastructure, ec2 instance, other aws resources (security groups, roles),

## Deploying rbennettio on fresh ec2 instance
TBD - describe system packages, ngnix, uwsgi
TBD - create a deployment script(s)?

## Backup and Restore SQLite3 Database
TBD - describe s3 bucket, versioning, s3 lifecycle management policy, reasoning for sqlite3 over postgresql

Add a crontab entry for the database backupscript
`crontab -e`
`0 5 * * * source </path/to/app.env> && </path/to/backup_database.sh>`
