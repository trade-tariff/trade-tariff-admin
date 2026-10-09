# Trade Tariff Admin

Trade Tariff Admin is the staff interface for the Online Trade Tariff. It is a
Ruby on Rails application for managing tariff content, search references, news,
Green Lanes assessments and data updates. It also provides search analytics and
diagnostics.

Most tariff data is read and changed through
[Trade Tariff Backend](https://github.com/trade-tariff/trade-tariff-backend).
Admin has its own PostgreSQL database for application records. It is not the
[public tariff service](https://www.gov.uk/trade-tariff), which is built
in [Trade Tariff Frontend](https://github.com/trade-tariff/trade-tariff-frontend).

## Run locally

### Prerequisites

- Ruby at the version in [.ruby-version](.ruby-version) and Bundler.
- Node.js and Yarn for the CSS build and JavaScript checks.
- PostgreSQL, with a local user that can create development and test databases.
- A local Trade Tariff Backend with tariff data for the journeys you need.

Clone this repository, or follow the [fork workflow](CONTRIBUTING.md#fork-and-branch)
if you want to contribute without write access.

### Configure the application

Keep local overrides in `.env.development.local`, not in the tracked defaults in
[.env.development](.env.development). Do not use production credentials or APIs
for local development.

`API_SERVICE_BACKEND_URL_OPTIONS` maps `uk` and `xi` to backend service roots.
Unlike the frontend, Admin expects URLs **without** `/api`, for example
`http://localhost:3000/uk`. Only enable services you have running locally.

[config/database.yml](config/database.yml) reads `PGHOST`, `DB_USER` and optional
`PGPASSWORD`. The default host is `localhost` and the default user is `postgres`.
The databases are `tariff_admin_development` and `tariff_admin_test`.

Authentication defaults to passwordless sign-in through
[Identity](https://github.com/trade-tariff/identity). This requires a configured
Identity consumer and matching `IDENTITY_BASE_URL`, `IDENTITY_CONSUMER`,
`IDENTITY_COGNITO_JWKS_URL` and `IDENTITY_ENCRYPTION_SECRET`. Keep secrets out of Git.
For isolated local development, `AUTH_STRATEGY=basic` uses a local
`BASIC_PASSWORD`. Do not change authentication on a shared environment to bypass
access controls.

### Set up and start

```sh
yarn install --frozen-lockfile
bin/setup --skip-server
bin/dev
```

`bin/setup` installs Ruby dependencies and prepares the database. Without
`--skip-server`, it also starts the application. `bin/dev` runs Rails and the CSS
watcher. Open <http://localhost:3003>.

## Run checks

With the test database available:

```sh
yarn build:css
RAILS_ENV=test bin/rails assets:precompile
RAILS_ENV=test bin/rails db:prepare
bundle exec rspec
yarn test
bundle exec rubocop
bundle exec brakeman
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for hooks and pull requests.
[GitHub Actions](.github/workflows/ci.yml) defines the CI checks.

## Find your way around

- [Routes](config/routes.rb): the staff journeys and available actions.
- [Controllers](app/controllers/) and [views](app/views/): page behaviour.
- [Models](app/models/): API-backed entities and local records.
- [Backend service selection](lib/trade_tariff_admin/service_chooser.rb): UK and XI configuration.
- [Deployment workflows](.github/workflows/): deployments to AWS, for maintainers.

## Sidekiq Web

Sidekiq Web shows the live queues, retries and dead jobs of the backend.
No page in the admin app links to it. Go to the URL directly.

| Service | Path |
| ------- | ---- |
| UK | `/sidekiq/uk` |
| XI | `/sidekiq/xi` |

`/sidekiq` redirects to `/sidekiq/uk`.

Only users with the `technical_operator` or `superadmin` role can open it.
Other users get a 404. Sign in to admin first.

The admin app reads the backend Sidekiq Redis with these variables:

- `SIDEKIQ_UK_REDIS_URL`
- `SIDEKIQ_XI_REDIS_URL`

In development and test, both default to `redis://localhost:6379/0`.
In production, both are required. Terraform reads them from the
`valkey-sidekiq-uk-connection-string` and
`valkey-sidekiq-xi-connection-string` secrets.

Sidekiq Web can delete queues, kill jobs and retry jobs. Take care in production.
The admin log records each request that can change Sidekiq data, with the
user uid and email (`[SidekiqWeb]` lines).

## Contribute

Read [CONTRIBUTING.md](CONTRIBUTING.md) for reporting bugs, making a fork,
submitting changes and reporting security issues privately.

## Licence

The code and associated documentation are available under the
[MIT licence](LICENSE.md), with the existing Crown copyright notice.
Keep the licence and copyright notice when you reuse the software.
Third-party dependencies and assets retain their own licences.
