# Food Storage Inventory

Tracks our long-term food storage, replacing the Numbers spreadsheet. It's a
Rails app with a [Madmin](https://github.com/excid3/madmin) admin interface:

- **Dashboard** (`/madmin`): items expiring in the next 4 months (including
  anything already expired) and the spreadsheet's supply summary — years
  supplied per food, how much more is needed for a year, and the shopping cost.
- **Foods** are the Summary sheet's rows (Wheat, Legumes, Vitamin C…), with a
  yearly per-person target and package size/price for the shopping list.
  **Items** are the stored containers or lots counted toward a food.
  **People** set the household size: each person counts as their daily calories
  ÷ 2,000.
- Adding items: "Save and add another" saves and opens a new form prefilled with
  the same details; "Copy and edit" on any item opens a prefilled new item form.
- **Notifications**: installed as a PWA, each phone can opt in to a push
  notification when items enter the 4-month window (checked Saturdays at 8am
  Mountain time).
- Background jobs (Solid Queue) are visible in Mission Control at `/jobs`.

## Development

```sh
bin/setup                 # installs gems, prepares the database, starts the server
npm install               # Playwright, for system specs
npx playwright install chromium
```

Create a user in `bin/rails console`:

```ruby
User.create!(email_address: "me@example.com", password: "a long password")
```

Users can then add other users and reset passwords under **Users** in the admin.
There is no emailed password reset.

Push notification (VAPID) keys live in Rails credentials, so they work locally
whenever `config/master.key` is present.

### Importing the spreadsheet

Export the Numbers spreadsheet as CSV (one file per table), unzip it, and run:

```sh
bin/rails "inventory:import[path/to/csv_directory]"
```

The import only runs on a database without items, so it can't double the
inventory. Year-only expiration dates ("2048") import as January 1 and
month/year dates ("8/27") as the first of the month, so they're flagged early;
"Eternity" and blank dates import as no expiration date.

### Checks

`bin/ci` runs RuboCop, bundler-audit, importmap audit, Brakeman, and RSpec
(model, request, job, and Playwright system specs). GitHub Actions runs the same
checks.

### Keeping dependencies up to date

Nothing updates dependencies automatically, and CI's security audit only runs
on push. Every month or so, update everything, check, and deploy:

```sh
bundle update
bin/importmap outdated   # pin any updates with bin/importmap pin <package>
bin/ci
bin/kamal deploy
```

Also bump the Litestream and Tailscale image versions in `config/deploy.yml` now
and then, reading their release notes first, then run
`bin/kamal accessory reboot <name>`.

## Credentials

Settings that shouldn't be in this public repository live in Rails credentials
(`bin/rails credentials:edit`):

```yaml
vapid:            # push notification keys; changing them breaks every phone's subscription
  subject: https://food-storage.example.ts.net
  public_key: ...
  private_key: ...
deploy:
  server: home-server                      # SSH host for Kamal
  ssh_user: conrad
  host: food-storage.example.ts.net        # the app's Tailscale HTTPS name; its first part names the Tailscale node
tailscale:
  auth_key: tskey-auth-...                 # only needed the first time the tailscale accessory boots
litestream:       # Cloudflare R2 backups; optional until set up (see Backups)
  endpoint: https://<account id>.r2.cloudflarestorage.com
  bucket: food-storage-inventory
  access_key_id: ...
  secret_access_key: ...
```

Kamal reads them through `.kamal/credentials.rb` when it renders
`config/deploy.yml`, `.kamal/secrets`, and the Litestream config, without
booting Rails.

## Deployment

The app deploys with [Kamal](https://kamal-deploy.org) to the home server, which
is only reachable over Tailscale:

- The `tailscale` accessory is a Tailscale node of its own (named after the
  first part of `deploy.host`) that provides HTTPS with a `*.ts.net`
  certificate and forwards to kamal-proxy. HTTPS is required for installing the
  PWA and for push notifications, and a separate name keeps the app's cookies
  and service worker apart from other apps on the server.
- kamal-proxy listens on `127.0.0.1:8380` and routes by host name. It's shared
  by every Kamal app on the server (Obsidian Reminders runs there too); keep
  their proxy settings in sync.
- Kamal runs a local registry and tunnels it over SSH, so no Docker Hub account
  is needed.

### First deploy

1. In the Tailscale admin console, make sure HTTPS certificates are enabled
   (DNS → HTTPS Certificates), then create an auth key (Settings → Keys →
   Generate auth key; one-off is fine) and put it in the `tailscale` credentials.
2. Deploy and create a user:
   ```sh
   bin/kamal setup
   bin/kamal console   # User.create!(email_address: ..., password: ...)
   ```
3. In the admin console's Machines list, open the new `food-storage` machine
   and **Disable key expiry**, so it doesn't drop off the tailnet in six months.
4. Import the spreadsheet into production:
   ```sh
   scp -r path/to/csv_directory home-server:/tmp/inventory_export
   ssh home-server 'docker cp /tmp/inventory_export $(docker ps -q -f label=service=food_storage_inventory -f label=role=web):/rails/tmp/'
   bin/kamal app exec --reuse 'bin/rails "inventory:import[/rails/tmp/inventory_export]"'
   ```

After that, `bin/kamal deploy` deploys new versions.

### Notifications on iPhone

iOS only allows push notifications for web apps added to the Home Screen
(iOS 16.4 or later):

1. Open the app's `https://food-storage.<tailnet>.ts.net` URL in Safari and sign in.
2. Share → **Add to Home Screen**.
3. Open Food Storage from the Home Screen and tap **Notify me about expiring
   items** on the dashboard.

Each phone subscribes separately. A notification goes out on the first Saturday
after items enter the 4-month window. If no phone can be reached, it's retried
the next Saturday.

## Backups

[Litestream](https://litestream.io) runs as a Kamal accessory next to the app
and continuously copies changes to `storage/production.sqlite3` to the
`food-storage-inventory` bucket in Cloudflare R2 (the Cloudflare dashboard,
under R2 Object Storage). It takes a full snapshot daily and keeps 30 days of
history (`config/litestream/litestream.yml.erb`), so the database can be
restored to any point in that window. The cache, queue, and cable databases
aren't backed up because their data is disposable.

This fits in R2's free tier (10 GB of storage and 1 million write requests a
month); the database is a few megabytes. The accessory is only configured once
the `litestream` credentials exist.

### Setup

1. In the Cloudflare dashboard, open R2 Object Storage and create a bucket named
   `food-storage-inventory` (Standard storage class; the free tier doesn't
   cover Infrequent Access).
2. Under R2 → **Manage API tokens**, create an Account API token with **Object
   Read & Write** permission for that bucket only and no expiration.
3. Add its access key ID and secret access key, the bucket name, and the
   S3 endpoint shown with the token to the `litestream` credentials.
4. `bin/kamal accessory boot litestream` (or `bin/kamal setup` on a new
   server), then check `bin/kamal accessory logs litestream` for errors.

### Checking the backup

`bin/check-backup` restores the latest backup from R2 beside the live database,
checks its integrity, compares its row counts and latest change with the live
database's, and deletes the copy. It fails if the backup is damaged or more
than five minutes behind. Run it about once a month, and after changing
Litestream's version or settings; agents do so when `tmp/backup-checked` (which
it touches on success) is missing or over 30 days old.

### Restoring onto a new server

If the home server dies, the backup comes back automatically: the Litestream
accessory restores the latest backup whenever the server has no database
(`config/litestream/start.sh`). On the replacement server:

1. Put the new server on the tailnet with SSH access (Kamal installs Docker).
2. Point `deploy.server` in the credentials at it, and put a new auth key in the
   `tailscale` credentials, since the old node's state stays on the dead server.
   Delete the old `food-storage` machine in the Tailscale admin console first,
   so the new one gets the same name.
3. Boot Litestream before the app, so the app doesn't create an empty database
   first:
   ```sh
   bin/kamal server bootstrap
   bin/kamal accessory boot litestream
   bin/kamal accessory logs litestream   # look for the restore, then "replicating to"
   bin/kamal deploy
   bin/kamal accessory boot tailscale
   ```

Phones need to re-enable notifications if the app's URL changed.

### Restoring an earlier point in time

To roll the existing server back, for example after a bad edit, restore into a
new file, swap it in, and clear Litestream's local state so it snapshots the
rolled-back database:

```sh
bin/kamal app stop
bin/kamal accessory stop litestream
bin/kamal accessory exec litestream "-c 'cd /rails/storage && litestream restore -timestamp 2026-10-01T00:00:00Z -o restored.sqlite3 /rails/storage/production.sqlite3 && rm -rf production.sqlite3-wal production.sqlite3-shm .production.sqlite3-litestream && mv restored.sqlite3 production.sqlite3 && chown 1000:1000 production.sqlite3'"
bin/kamal accessory start litestream
bin/kamal app boot
```

The accessory's entrypoint is `/bin/sh`, hence the `-c`. Leave out `-timestamp`
to restore the latest backup.
