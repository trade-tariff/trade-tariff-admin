# Build compilation image
FROM ruby:3.0.3-alpine3.13 as builder

# The application runs from /app
WORKDIR /app

# build-base: compilation tools for bundle
# git: used to pull gems from git
# yarn: node package manager
RUN apk add --update --no-cache build-base git yarn postgresql-dev tzdata && \
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

ENV GOVUK_APP_DOMAIN=localhost
ENV GOVUK_WEBSITE_ROOT=http://localhost/
ENV RAILS_ENV=production
ENV SECRET_TOKEN="foo"
ENV SECRET_KEY_BASE="bar"

RUN bundle exec rails assets:precompile

# Cleanup to save space in the production image
RUN rm -rf node_modules log tmp && \
      rm -rf /usr/local/bundle/cache && \
      rm -rf .env && \
      find /usr/local/bundle/gems -name "*.c" -delete && \
      find /usr/local/bundle/gems -name "*.h" -delete && \
      find /usr/local/bundle/gems -name "*.o" -delete && \
      find /usr/local/bundle/gems -name "*.html" -delete

# Build runtime image
FROM ruby:3.0.3-alpine3.13 as production

RUN apk add --update --no-cache tzdata postgresql-dev nodejs && \
  cp /usr/share/zoneinfo/Europe/London /etc/localtime && \
  echo "Europe/London" > /etc/timezone

# The application runs from /app
WORKDIR /app

ENV RAILS_SERVE_STATIC_FILES=true
ENV RAILS_ENV=production

# Copy files generated in the builder image
COPY --from=builder /app /app
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]