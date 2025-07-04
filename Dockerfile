# Build compilation image
ARG RUBY_VERSION=3.4.4
ARG ALPINE_VERSION=3.21

FROM ruby:${RUBY_VERSION}-alpine${ALPINE_VERSION} AS builder

# The application runs from /app
WORKDIR /app

RUN apk add --update --no-cache \
  build-base \
  git \
  postgresql-dev \
  sqlite \
  tzdata \
  yaml-dev \
  yarn && \
  cp /usr/share/zoneinfo/Europe/London /etc/localtime && \
  echo "Europe/London" > /etc/timezone

RUN bundle config set without 'development test'

# Install gems defined in Gemfile
COPY .ruby-version Gemfile Gemfile.lock /app/
RUN bundle install --jobs=4 --no-binstubs

# Install node packages defined in package.json, including webpack
COPY package.json yarn.lock /app/
RUN yarn install --frozen-lockfile

# Copy all files to /app (except what is defined in .dockerignore)
COPY . /app/

ENV GOVUK_APP_DOMAIN=localhost \
  GOVUK_WEBSITE_ROOT=http://localhost/ \
  RAILS_ENV=production \
  SECRET_TOKEN="foo" \
  SECRET_KEY_BASE="bar" \
  NODE_OPTIONS="--openssl-legacy-provider"

RUN bundle exec rails webpacker:compile

# Cleanup to save space in the production image
RUN rm -rf node_modules log tmp && \
  rm -rf /usr/local/bundle/cache && \
  rm -rf .env && \
  find /usr/local/bundle/gems -name "*.c" -delete && \
  find /usr/local/bundle/gems -name "*.h" -delete && \
  find /usr/local/bundle/gems -name "*.o" -delete && \
  find /usr/local/bundle/gems -name "*.html" -delete

# Build runtime image
FROM ruby:${RUBY_VERSION}-alpine${ALPINE_VERSION} AS production

RUN apk add --update --no-cache tzdata postgresql-dev nodejs sqlite && \
  cp /usr/share/zoneinfo/Europe/London /etc/localtime && \
  echo "Europe/London" > /etc/timezone

# The application runs from /app
WORKDIR /app

ENV RAILS_SERVE_STATIC_FILES=true \
  RAILS_ENV=production \
  PORT=8080

# Copy files generated in the builder image
COPY --from=builder /app /app
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/


RUN bundle config set without 'development test'
RUN addgroup -S tariff && \
  adduser -S tariff -G tariff && \
  chown -R tariff:tariff /app && \
  chown -R tariff:tariff /usr/local/bundle

HEALTHCHECK CMD nc -z 0.0.0.0 $PORT

USER tariff

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
