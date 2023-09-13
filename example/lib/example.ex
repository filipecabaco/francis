defmodule Example do
  use Francis

  get("/", fn _ -> "<html><body><h1>Hello, world!</h1></body></html>" end)
  get("/:name", fn %{params: %{"name" => name}} -> "hello #{name}" end)

  ws("ws", fn "ping" -> "pong" end)

  unmatched(fn _ -> "not found" end)
end
