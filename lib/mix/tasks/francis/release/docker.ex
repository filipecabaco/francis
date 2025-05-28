defmodule Mix.Tasks.Francis.Release.Docker do
  @moduledoc false

  @behaviour Mix.Tasks.Francis.Release

  @impl true
  @doc "Generates Docker and .dockerignore for deployment."
  @spec generate_files(keyword()) :: :ok
  def generate_files(args) do
    app = Mix.Project.config() |> Keyword.fetch!(:app)
    port = Keyword.get(args, :port, 4000)
    elixir_version = Keyword.get(args, :elixir_version, "1.18.4")
    opt_version = Keyword.get(args, :elixir_version, "27.3.4")
    docker_file = dockerfile_template(app, port, elixir_version, opt_version)
    docker_ignore = dockerignore_template()

    Mix.Generator.create_file("Dockerfile", docker_file)
    Mix.Generator.create_file(".dockerignore", docker_ignore)
  end

  defp dockerfile_template(app, port, elixir_version, otp_version) do
    """
    # Build Stage
    ARG ELIXIR_VERSION=#{elixir_version}
    ARG OTP_VERSION=#{otp_version}
    ARG DEBIAN_VERSION=bookworm-20250520-slim
    ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
    ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

    FROM ${BUILDER_IMAGE} AS build
    ENV MIX_ENV=prod

    # Install build dependencies
    RUN apt-get update -y && apt-get install curl -y && apt-get install -y build-essential git && apt-get clean
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
    COPY --from=build /app/_build/prod/rel/#{app} ./
    COPY --from=build /app/priv ./priv

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
