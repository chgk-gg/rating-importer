ARG RUBY_VERSION=3.3.3
FROM ruby:$RUBY_VERSION-slim as base

# Rack app lives here
WORKDIR /app

# Update gems and bundler
RUN gem update --system --no-document && \
    gem install -N bundler


# Throw-away build stage to reduce size of final image
FROM base as build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libpq-dev

# Install application gems
COPY Gemfile* .
RUN bundle install


# Final stage for app image
FROM base

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y libpq-dev curl postgresql-client postgresql-client-common

ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.2/supercronic-linux-amd64 \
    SUPERCRONIC=supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=2319da694833c7a147976b8e5f337cd83397d6be

RUN curl -fsSLO "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

# Run and own the application files as a non-root user for security
RUN useradd ruby --home /app --shell /bin/bash

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=ruby:ruby /app /app

RUN chmod -R 777 /app

USER ruby:ruby

# Copy application code
COPY . .
