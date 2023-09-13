# Francis

> Nothing is stable! Try it out with caution

Simple boilerplate killer using Plug and Bandit inspired by [Sinatra](https://sinatrarb.com) for Ruby

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `francis` to your list of dependencies in `mix.exs`:

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

## Example using it with Mix.install

```elixir
  # create a new file called server.ex
  Mix.install([:francis])
  
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
  
  Example.start(nil, nil)
  Process.sleep(:infinity)
  # run this file with elixir server.ex
```

Check the folder [example](https://github.com/filipecabaco/francis/tree/main/example) to check the code.
