defmodule Support.WsTester do
  @moduledoc """
  Websocket client to test Francis websocket routes
  """
  use WebSockex

  def start_link(state), do: WebSockex.start_link(state.url, __MODULE__, state)

  def handle_frame({:text, msg}, %{parent_pid: parent_pid} = state) when is_binary(msg) do
    case Jason.decode(msg) do
      {:ok, decoded_msg} -> send(parent_pid, {:client, decoded_msg})
      {:error, _} -> send(parent_pid, {:client, msg})
    end

    {:ok, state}
  end
end
