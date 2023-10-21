defmodule Mix.Tasks.Francis.Release.Docker do
  @moduledoc """
  Generates Docker and .dockerignore for deployment
  """

  @behaviour Mix.Tasks.Francis.Release

  @impl true
  def generate_files(args) do
    app = Mix.Project.config() |> Keyword.fetch!(:app)
    port = Keyword.get(args, :port, 4000)

    docker_file = dockerfile_template(app, port)
    docker_ignore = dockerignore_template()

    File.write!("Dockerfile", docker_file)
    File.write!(".dockerignore", docker_ignore)
  end

  defp dockerfile_template(app, port) do
    """
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
    COPY --from=build /app/_build/prod/rel/#{app} ./

    # Set environment variables
    ENV HOME=/app

    # Expose port
    EXPOSE #{port}

    # Start the application
    CMD ["bin/#{app}", "start"]
    """
  end

  defp dockerignore_template do
    """
      .git
      _build
      deps
      doc
      .elixir_ls
    """
  end
end
