defmodule Mix.Tasks.Francis.Release do
  @moduledoc """
  Generates files for Francis deployment in multiple environments.

  ## Command line options

  * `docker` - Generates Docker and .dockerignore for deployment
    * `port` - Port to be exposed in Docker container (port=4001) . Defaults to 4000
  """
  use Mix.Task
  alias Mix.Tasks.Francis.Release.Docker

  @shortdoc "Generates files for Francis deployment"

  @callback generate_files(args :: list) :: any()

  @impl true
  def run(args) do
    case args do
      ["docker" | args] -> args |> args_to_keyword |> Docker.generate_files()
      [] -> Mix.raise("No option given")
      _ -> Mix.raise("Unknown option: #{inspect(args)}")
    end
  end

  defp args_to_keyword(args) do
    args
    |> Enum.map(fn arg -> String.split(arg, "=") end)
    |> Enum.map(fn [k, v] -> {String.to_existing_atom(k), v} end)
    |> Keyword.new()
  end
end
