defmodule Francis.Watcher do
  @moduledoc """
  Watcher mode for development that checks modified time of your files and recompiles them
  """
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{files: %{}})
  end

  def init(state) do
    Logger.debug("Development watch mode enabled")
    Code.put_compiler_option(:ignore_module_conflict, true)
    Process.send_after(self(), :check, 100)
    {:ok, state}
  end

  # sobelow_skip ["RCE.CodeModule"]
  def handle_info(:check, %{files: files} = state) do
    files =
      Enum.reduce(Path.wildcard("./**/*.{ex,exs}"), files, fn path, files ->
        new_mtime = File.stat!(path).mtime

        case Map.get(files, path) do
          mtime when not is_nil(mtime) and new_mtime != mtime -> Code.eval_file(path)
          _ -> nil
        end

        Map.put(files, path, File.stat!(path).mtime)
      end)

    Process.send_after(self(), :check, 100)
    {:noreply, %{state | files: files}}
  end
end
