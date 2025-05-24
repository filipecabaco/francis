defmodule Support.WsTester do
  @moduledoc """
  Websocket client to test Francis websocket routes
  """
  use WebSockex

  def start_link(state), do: WebSockex.start_link(state.url, __MODULE__, state)

  def handle_frame({:text, msg}, %{parent_pid: parent_pid} = state) do
    send(parent_pid, {:client, msg})
    {:ok, state}
  end
end
