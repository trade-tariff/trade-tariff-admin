# Trade Tariff Admin

The admin interface for the the Trade Tariff, to be used with:

* [Trade Tariff Backend](https://github.com/alphagov/trade-tariff-backend)
* [Trade Tariff Frontend](https://github.com/alphagov/trade-tariff-frontend)

Please ensure the backend API is running and properly configured in the
environment files, see the backend's [README](https://github.com/trade-tariff/trade-tariff-backend/blob/main/README.md)

## Dependencies

> Make sure you install and enable all pre-commit hooks https://pre-commit.com/

* Ruby (see .ruby-version for current version)
* NodeJS
* SQLite3 (`brew install sqlite`)

## Setup

```
$ bin/setup
```

## Run Trade Tariff Admin

```
$ bundle exec rails s
```

## Run the test suite

```
$ bundle exec rspec
```

## Authentication configuration

* `AUTH_STRATEGY` controls auth mode: `passwordless` (default) or `basic` (requires `BASIC_PASSWORD`).
* Passwordless auth also uses `IDENTITY_BASE_URL` (default `http://localhost:3005`), `IDENTITY_CONSUMER` (default `admin`), optional `IDENTITY_COGNITO_JWKS_URL`, and `IDENTITY_ENCRYPTION_SECRET`.

## Deployment to GOV PaaS

Deployments are handled via CI
