defmodule Support.PlugTester do
  import Plug.Conn
  def init(opts), do: opts

  def call(%{assigns: assigns} = conn, to_assign: to_assign) do
    case Map.get(assigns, :plug_assgined) do
      nil -> assign(conn, :plug_assgined, [to_assign])
      value -> assign(conn, :plug_assgined, value ++ [to_assign])
    end
  end
end
