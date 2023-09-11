# Frank

> Nothing is stable! Try it out with caution

Simple boilerplate killer using Plug and Bandit inspired by [Sinatra](sinatrarb.com) for Ruby

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `frank` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:francis, "~> 0.1.0-pre"}
  ]
end
```

## Example
```elixir
defmodule Example do
  use Francis

  get("/", fn _ -> "<html>world</html>" end)
  get("/:name", fn %{params: %{"name" => name}} -> "hello #{name}" end)

  ws("ws", fn "ping" -> "pong" end)

  unmatched(fn _ -> "not found" end)
end
```
Check the folder (example)[/example] to check the code.