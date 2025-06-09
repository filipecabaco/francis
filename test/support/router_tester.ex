defmodule Support.RouteTester do
  @moduledoc """
  Generates test modules with Francis to test routes in isolation.
  """
  def generate_module(handlers \\ nil, opts \\ []) do
    mod = Module.concat(Elixir, "TestMod#{random_string()}")
    plugs = Keyword.get(opts, :plugs, [])
    static = Keyword.get(opts, :static)
    parser = Keyword.get(opts, :parser)
    bandit_opts = Keyword.get(opts, :bandit_opts, [])
    error_handler = Keyword.get(opts, :error_handler)

    content =
      quote do
        use Francis,
          plugs: unquote(plugs),
          static: unquote(static),
          parser: unquote(parser),
          bandit_opts: unquote(bandit_opts),
          error_handler: unquote(error_handler)

        unquote(handlers)
      end

    Module.create(mod, content, Macro.Env.location(__ENV__))
    mod
  end

  defp random_string do
    System.unique_integer([:positive])
    |> Integer.to_string(36)
    |> Base.encode16(case: :upper)
  end
end
