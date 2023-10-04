defmodule Support.WsTester do
  use WebSockex

  def start(url, parent_pid) do
    WebSockex.start(url, __MODULE__, %{parent_pid: parent_pid})
  end

  def handle_frame({:text, msg}, %{parent_pid: parent_pid} = state) do
    send(parent_pid, {:client, msg})
    {:ok, state}
  end
end
