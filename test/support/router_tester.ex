defmodule Support.RouteTester do
  @moduledoc """
  Generates test modules with Francis to test routes in isolation
  """
  def generate_module(handlers \\ nil, opts \\ []) do
    mod = "Elixir.TestMod#{random_string()}" |> String.to_atom()
    plugs = Keyword.get(opts, :plugs, [])
    static = Keyword.get(opts, :static)

    ast =
      quote do
        defmodule unquote(mod) do
          use Francis,
            plugs: unquote(plugs),
            static: unquote(static)

          unquote(handlers)
        end
      end

    Code.compile_quoted(ast)
    mod
  end

  defp random_string do
    10
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :upper)
  end
end
