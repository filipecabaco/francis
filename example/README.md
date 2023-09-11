# Example

Simple example for Francis with one get endpoint, a websocket handler and a handle for unmatched routes.

## Run

Run it with `mix run --no-halt`

### Override Application startup

In the `mix.exs` file we define that the module to start is `Example`. You can override `start/2` if you need to.

That change would look like this:

```elixir
defmodule Example do
  use Francis

  get("/", fn _ -> "<html>world</html>" end)
  get("/:name", fn %{params: %{"name" => name}} -> "hello #{name}" end)

  ws("ws", fn "ping" -> "pong" end)

  unmatched(fn _ -> "not found" end)

  def start(_, _) do
    children = [{Bandit, [plug: __MODULE__]}]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```
