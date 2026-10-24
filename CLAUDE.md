Run `bin/ci` before merging.

Check production's backup about once a month: if `tmp/backup-checked` is missing or more than 30 days old, run
`bin/check-backup` at the start of a session and tell the user the result. It restores the latest Litestream backup
from R2 beside the live database, compares the two, and deletes the copy; it doesn't change the live database.
