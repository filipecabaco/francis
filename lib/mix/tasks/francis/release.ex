defmodule Mix.Tasks.Francis.Release do
  @moduledoc """
  Generates docker files for Francis deployment

  ## Command line options

  * `port` - Port to be exposed in Docker container (port=4000) . Defaults to 4000
  """
  use Mix.Task
  alias Mix.Tasks.Francis.Release.Docker

  @shortdoc "Generates files for Francis deployment"

  @callback generate_files(args :: list) :: any()

  @impl true
  def run(args) do
    args |> args_to_keyword() |> Docker.generate_files()
  end

  defp args_to_keyword(args) do
    {opts, _positional, _invalid} =
      OptionParser.parse(args, strict: [port: :integer], aliases: [p: :port])

    opts
  end
end
