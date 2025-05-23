# Build Stage
ARG ELIXIR_VERSION=1.18.4
ARG OTP_VERSION=27.3.4
ARG DEBIAN_VERSION=bookworm-20250520-slim
ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} AS build
ENV MIX_ENV=prod

# Install build dependencies
RUN apt-get update -y     && apt-get install curl -y     && apt-get install -y build-essential git     && apt-get clean
# Set working directory
WORKDIR /app

# Copy application code
COPY . .

# Install dependencies
RUN mix local.hex --force && mix local.rebar --force && mix deps.get && mix compile
# Build the release
RUN mix release

# Run Stage
FROM ${RUNNER_IMAGE} AS run

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install runtime dependencies
RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
# Set working directory
WORKDIR /app

# Copy the release from the build stage
COPY --from=build /app/_build/prod/rel/example ./

# Set environment variables
ENV HOME=/app

# Expose port
EXPOSE 4000

# Start the application
CMD ["bin/example", "start"]
