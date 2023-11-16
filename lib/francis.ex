defmodule Francis do
  @moduledoc """
  Module responsible for starting the Francis server and to wrap the Plug functionality

  This module performs multiple tasks:
    * Uses the Application module to start the Francis server
    * Defines the Francis.Router which uses Francis.Plug.Router, :match and :dispatch
    * Defines the macros get, post, put, delete, patch and ws to define routes for each operation

  You can also set the following options:
    * :bandit_opts - Options to be passed to Bandit
    * :plugs - List of plugs to be used by Francis
  """
  import Plug.Conn

  defmacro __using__(opts \\ []) do
    quote location: :keep do
      use Application

      def start, do: start(nil, nil)

      def start(_type, _args) do
        children = [
          {Bandit, [plug: __MODULE__] ++ Keyword.get(unquote(opts), :bandit_opts, [])}
        ]

        Supervisor.start_link(children, strategy: :one_for_one)
      end

      defoverridable(start: 2)

      defp handle_response(handler, conn, status \\ 200) do
        case handler.(conn) do
          res when is_struct(res, Plug.Conn) ->
            res

          res when is_binary(res) ->
            conn
            |> send_resp(status, res)
            |> halt()

          res when is_map(res) or is_list(res) ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(status, Jason.encode!(res))
            |> halt()
        end
      end

      use Francis.Plug.Router

      plug(:match)

      Enum.each(Keyword.get(unquote(opts), :plugs, []), fn
        plug when is_atom(plug) -> plug(plug)
        {plug, opts} when is_atom(plug) -> plug(plug, opts)
      end)

      plug(:dispatch)
    end
  end

  @doc """
  Defines a GET route

  ## Examples

  ```
  defmodule Example.Router do
    use Francis

    get "/hello", fn conn ->
      "Hello World!"
    end
  end
  ```
  """
  defmacro get(path, handler) do
    quote location: :keep do
      Plug.Router.get(unquote(path), do: handle_response(unquote(handler), var!(conn)))
    end
  end

  @doc """
  Defines a POST route

  ## Examples

  ```
  defmodule Example.Router do
    use Francis

    post "/hello", fn conn ->
      "Hello World!"
    end
  end
  ```
  """

  defmacro post(path, handler) do
    quote location: :keep do
      Plug.Router.post(unquote(path), do: handle_response(unquote(handler), var!(conn)))
    end
  end

  @doc """
  Defines a PUT route

  ## Examples

  ```
  defmodule Example.Router do
    use Francis

    put "/hello", fn conn ->
      "Hello World!"
    end
  end
  ```
  """

  defmacro put(path, handler) do
    quote location: :keep do
      Plug.Router.put(unquote(path), do: handle_response(unquote(handler), var!(conn)))
    end
  end

  @doc """
  Defines a DELETE route

  ## Examples

  ```
  defmodule Example.Router do
    use Francis

    delete "/hello", fn conn ->
      "Hello World!"
    end
  end
  ```
  """

  defmacro delete(path, handler) do
    quote location: :keep do
      Plug.Router.delete(unquote(path), do: handle_response(unquote(handler), var!(conn)))
    end
  end

  @doc """
  Defines a PATCH route

  ## Examples

  ```elixir
  defmodule Example.Router do
    use Francis

    patch "/hello", fn conn ->
      "Hello World!"
    end
  end
  ```
  """

  defmacro patch(path, handler) do
    quote location: :keep do
      Plug.Router.patch(unquote(path), do: handle_response(unquote(handler), var!(conn)))
    end
  end

  @doc """
  Defines a WebSocket route that sends text type responses

  ## Examples

  ```elixir
  defmodule Example.Router do
    use Francis

    ws "/hello", fn _ ->
      "Hello World!"
    end
  end
  ```
  """

  defmacro ws(path, handler) do
    module_name =
      path
      |> URI.parse()
      |> then(& &1.path)
      |> then(&String.split(&1, "/"))
      |> Enum.map_join(".", &String.capitalize/1)
      |> then(&"#{__MODULE__}.#{&1}")
      |> String.to_atom()

    handler_ast =
      quote do
        defmodule unquote(module_name) do
          require WebSockAdapter

          require Logger
          def init(_opts), do: {:ok, %{}}

          def handle_in(message, state) do
            case unquote(handler).(elem(message, 0)) do
              res when is_binary(res) ->
                {:push, [{:text, res}], state}

              res when is_map(res) ->
                {:push, [{:text, Jason.encode!(res)}], state}
            end
          rescue
            e ->
              Logger.error("WS Handler error: #{inspect(e)} ")
              {:stop, :error, e}
          end

          def terminate(reason, state) do
            Logger.info("WS Handler terminated: #{inspect(reason)} ")
            :ok
          end
        end
      end

    Code.compile_quoted(handler_ast)

    quote location: :keep do
      get(unquote(path), fn conn ->
        var!(conn)
        |> WebSockAdapter.upgrade(unquote(module_name), [], timeout: 60_000)
        |> halt()
      end)
    end
  end

  @doc """
  Defines an action for umatched routes and returns 404
  """
  defmacro unmatched(handler) do
    quote location: :keep do
      match _ do
        handle_response(unquote(handler), var!(conn), 404)
      end
    end
  end
end
