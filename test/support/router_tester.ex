defmodule Support.RouteTester do
  def generate_module(handlers) do
    mod = "Elixir.TestMod#{random_string()}" |> String.to_atom()

    ast =
      quote do
        defmodule unquote(mod) do
          use Francis
          unquote(handlers)
        end
      end

    Code.compile_quoted(ast)
    mod
  end

  defp random_string() do
    10
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :upper)
  end
end
