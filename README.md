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
  notification when items enter the 4-month window (checked daily at 8am
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

## Credentials

Settings that shouldn't be in this public repository live in Rails credentials
(`bin/rails credentials:edit`):

```yaml
vapid:            # push notification keys; changing them breaks every phone's subscription
  subject: https://home-server.example.ts.net
  public_key: ...
  private_key: ...
deploy:
  server: home-server                      # SSH host for Kamal
  ssh_user: conrad
  host: home-server.example.ts.net         # the app's Tailscale HTTPS name
litestream:       # optional until backups are set up (see Backups)
  host: backup-machine.example.ts.net:22
  user: litestream
  path: /path/to/backups/food_storage_inventory
  host_key: ssh-ed25519 AAAA...
  ssh_private_key: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    ...
```

Kamal reads them through `.kamal/credentials.rb` when it renders
`config/deploy.yml` and the Litestream config, without booting Rails.

## Deployment

The app deploys with [Kamal](https://kamal-deploy.org) to the home server, which
is only reachable over Tailscale:

- kamal-proxy listens on `127.0.0.1:8380`, not ports 80/443, so it doesn't
  collide with other services. kamal-proxy is shared by every Kamal app on a
  server; if another Kamal app is added there, keep their proxy settings in sync.
- [Tailscale Serve](https://tailscale.com/kb/1242/tailscale-serve) provides
  HTTPS with a `*.ts.net` certificate. HTTPS is required for installing the PWA
  and for push notifications.
- Kamal runs a local registry and tunnels it over SSH, so no Docker Hub account
  is needed.

### First deploy

1. Enable HTTPS certificates for the tailnet (Tailscale admin console → DNS),
   then on the home server:
   ```sh
   sudo tailscale serve --bg --https=443 http://127.0.0.1:8380
   ```
2. Deploy and create a user:
   ```sh
   bin/kamal setup
   bin/kamal console   # User.create!(email_address: ..., password: ...)
   ```
3. Import the spreadsheet into production:
   ```sh
   scp -r path/to/csv_directory home-server:/tmp/inventory_export
   ssh home-server 'docker cp /tmp/inventory_export $(docker ps -q -f label=service=food_storage_inventory -f label=role=web):/rails/tmp/'
   bin/kamal app exec --reuse 'bin/rails "inventory:import[/rails/tmp/inventory_export]"'
   ```

After that, `bin/kamal deploy` deploys new versions.

### Notifications on iPhone

iOS only allows push notifications for web apps added to the Home Screen
(iOS 16.4 or later):

1. Open the app's `https://home-server.<tailnet>.ts.net` URL in Safari and sign in.
2. Share → **Add to Home Screen**.
3. Open Food Storage from the Home Screen and tap **Notify me about expiring
   items** on the dashboard.

Each phone subscribes separately. A notification goes out the first day items
enter the 4-month window. If no phone can be reached that day, it's retried the
next day.

## Backups

[Litestream](https://litestream.io) runs as a Kamal accessory next to the app.
It continuously copies changes to `storage/production.sqlite3` over SFTP to
another machine on the tailnet, takes a full snapshot daily, and keeps 30 days
of history (`config/litestream/litestream.yml.erb`), so the database can be
restored to any point in that window. The cache, queue, and cable databases
aren't backed up because their data is disposable. The accessory is only
configured once the `litestream` credentials exist.

Setup:

1. On the backup machine (any always-on machine on the tailnet with SSH), create
   a user and a backup directory owned by it.
2. Create a key pair just for backups and authorize it for that user:
   ```sh
   ssh-keygen -t ed25519 -N "" -C litestream -f litestream_key
   ssh-copy-id -i litestream_key.pub litestream@backup-machine
   ```
3. Add the `litestream` credentials: the private key's contents as
   `ssh_private_key`, and the backup machine's host key from
   `ssh-keyscan -t ed25519 backup-machine` (without the leading hostname) as
   `host_key`. Then delete the local key files.
4. `bin/kamal accessory boot litestream` and check
   `bin/kamal accessory logs litestream` for a successful sync.

Do a practice restore once backups are running.

### Restoring

```sh
bin/kamal app stop
bin/kamal accessory exec litestream "litestream restore -o /rails/storage/restored.sqlite3 /rails/storage/production.sqlite3"
bin/kamal accessory exec litestream "sh -c 'mv /rails/storage/restored.sqlite3 /rails/storage/production.sqlite3 && rm -f /rails/storage/production.sqlite3-wal /rails/storage/production.sqlite3-shm'"
bin/kamal accessory reboot litestream
bin/kamal app boot
```

Add `-timestamp 2026-10-01T00:00:00Z` to the restore command to restore an
earlier point in time.
