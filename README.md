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

To try push notifications locally, generate VAPID keys and export them before
starting the server:

```sh
bin/rails runner 'k = WebPush.generate_key; puts "export VAPID_PUBLIC_KEY=#{k.public_key} VAPID_PRIVATE_KEY=#{k.private_key}"'
export VAPID_SUBJECT=mailto:me@example.com
```

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

## Deployment

The app deploys with [Kamal](https://kamal-deploy.org) to the home server, which
is only reachable over Tailscale. Because the server runs other services:

- kamal-proxy listens on `127.0.0.1:8380`, not ports 80/443. kamal-proxy is
  shared by every Kamal app on a server, so if another Kamal app already runs
  there, check its proxy ports before booting.
- [Tailscale Serve](https://tailscale.com/kb/1242/tailscale-serve) provides
  HTTPS with a `*.ts.net` certificate. HTTPS is required for installing the PWA
  and for push notifications.
- Kamal runs a local registry and tunnels it over SSH, so no Docker Hub account
  is needed.

### First deploy

1. Replace the `HOME_SERVER`, `TAILNET`, and `BACKUP_*` placeholders in
   `config/deploy.yml`. Kamal connects over SSH as `root` by default; add an
   `ssh: user:` entry if you deploy as a different user who can run Docker.
2. Enable HTTPS certificates for the tailnet (Tailscale admin console → DNS),
   then on the home server:
   ```sh
   sudo tailscale serve --bg --https=443 http://127.0.0.1:8380
   ```
   If port 443 on the server's Tailscale address is already taken, use another
   port (e.g. `--https=8443`) and visit `https://HOME_SERVER.TAILNET.ts.net:8443`.
3. Generate VAPID keys (see Development), store them in your password manager,
   and export `VAPID_PUBLIC_KEY` and `VAPID_PRIVATE_KEY` in the shell you deploy
   from. Keep them stable; new keys invalidate every phone's subscription.
4. Set up backups (below), then deploy and create a user:
   ```sh
   bin/kamal setup
   bin/kamal console   # User.create!(email_address: ..., password: ...)
   ```
5. Import the spreadsheet into production:
   ```sh
   scp -r path/to/csv_directory HOME_SERVER:/tmp/inventory_export
   ssh HOME_SERVER 'docker cp /tmp/inventory_export $(docker ps -q -f label=service=food_storage_inventory -f label=role=web):/rails/tmp/'
   bin/kamal app exec --reuse 'bin/rails "inventory:import[/rails/tmp/inventory_export]"'
   ```

After that, `bin/kamal deploy` deploys new versions.

### Notifications on iPhone

iOS only allows push notifications for web apps added to the Home Screen
(iOS 16.4 or later):

1. Open the app's `https://HOME_SERVER.TAILNET.ts.net` URL in Safari and sign in.
2. Share → **Add to Home Screen**.
3. Open Food Storage from the Home Screen and tap **Notify me about expiring
   items** on the dashboard.

Each phone subscribes separately. A notification goes out the first day items
enter the 4-month window. If no phone can be reached that day, it's retried the
next day.

## Backups

[Litestream](https://litestream.io) runs as a Kamal accessory and continuously
replicates `storage/production.sqlite3` over SFTP to another machine on the
tailnet. It takes a snapshot daily and keeps 30 days of history
(`config/litestream.yml`). The cache, queue, and cable databases aren't backed
up because their data is disposable.

Setup:

1. On the backup machine, create a user and a backup directory, and add an
   ed25519 public key to that user's `authorized_keys`.
2. On the home server, put the matching private key at
   `/etc/food_storage_inventory/litestream/id_ed25519` (readable only by root).
3. Set `BACKUP_HOST`, `BACKUP_USER`, `BACKUP_PATH`, and `BACKUP_HOST_KEY` (from
   `ssh-keyscan -t ed25519 BACKUP_MACHINE`) in `config/deploy.yml`.
4. `bin/kamal accessory boot litestream` (`bin/kamal setup` also boots it).

Check on replication with `bin/kamal accessory logs litestream`. Do a practice
restore once backups are running.

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
