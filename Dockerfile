# Build Stage
FROM elixir:1.15-alpine AS build
ENV MIX_ENV=prod

# Install build dependencies
RUN apk add --no-cache build-base

# Set working directory
WORKDIR /app

# Copy application code
COPY . .

# Install dependencies
RUN mix local.hex --force &&     mix local.rebar --force &&     mix deps.get &&     mix deps.compile

# Build the release
RUN mix release

# Run Stage
FROM alpine:3.14 AS run

# Install runtime dependencies
RUN apk add --no-cache openssl

# Set working directory
WORKDIR /app

# Copy the release from the build stage
COPY --from=build /app/_build/prod/rel/francis ./

# Set environment variables
ENV HOME=/app

# Expose port
EXPOSE 4000

# Start the application
CMD ["bin/francis", "start"]
