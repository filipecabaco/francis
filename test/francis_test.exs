defmodule FrancisTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias Francis

  describe "get/1" do
    test "returns a response with the given body" do
      handler = quote do: get("/", fn _ -> "test" end)
      mod = Support.RouteTester.generate_module(handler)

      assert Req.get!("/", plug: mod).body == "test"
    end
  end

  describe "post/1" do
    test "returns a response with the given body" do
      handler = quote do: post("/", fn _ -> "test" end)
      mod = Support.RouteTester.generate_module(handler)

      assert Req.post!("/", plug: mod).body == "test"
    end
  end

  describe "put/1" do
    test "returns a response with the given body" do
      handler = quote do: put("/", fn _ -> "test" end)
      mod = Support.RouteTester.generate_module(handler)

      assert Req.put!("/", plug: mod).body == "test"
    end
  end

  describe "delete/1" do
    test "returns a response with the given body" do
      handler = quote do: delete("/", fn _ -> "test" end)
      mod = Support.RouteTester.generate_module(handler)

      assert Req.delete!("/", plug: mod).body == "test"
    end
  end

  describe "patch/1" do
    test "returns a response with the given body" do
      handler = quote do: patch("/", fn _ -> "test" end)
      mod = Support.RouteTester.generate_module(handler)

      assert Req.patch!("/", plug: mod).body == "test"
    end

    test "setups a HEAD handler" do
      handler = quote do: get("/", fn _ -> "test" end)
      mod = Support.RouteTester.generate_module(handler)

      assert Req.head!("/", plug: mod).status == 200
      assert Req.head!("/", plug: mod).body == ""
    end
  end

  describe "ws/1" do
    setup do
      port = Enum.random(5000..10_000)

      %{port: port}
    end

    test "returns a response with the given body", %{port: port} do
      parent_pid = self()
      path = 10 |> :crypto.strong_rand_bytes() |> Base.encode16(case: :lower)

      handler =
        quote do
          ws(unquote(path), fn "test", socket ->
            send(unquote(parent_pid), {:handler, "handler_received"})
            send(socket.transport, "late_sent")
            send(socket.transport, %{key: "value"})
            send(socket.transport, [1, 2, 3])
            {:reply, "reply"}
          end)
        end

      bandit_opts = [port: port]
      mod = Support.RouteTester.generate_module(handler, bandit_opts: bandit_opts)

      assert capture_log(fn ->
               {:ok, _} = start_supervised(mod)
             end) =~
               "Running #{mod |> Module.split() |> List.last()} with Bandit #{Application.spec(:bandit, :vsn)} at 0.0.0.0:#{port}"

      tester_pid =
        start_supervised!(
          {Support.WsTester, %{url: "ws://localhost:#{port}/#{path}", parent_pid: parent_pid}}
        )

      WebSockex.send_frame(tester_pid, {:text, "test"})
      assert_receive {:handler, "handler_received"}
      assert_receive {:client, "late_sent"}
      assert_receive {:client, %{"key" => "value"}}
      assert_receive {:client, [1, 2, 3]}

      :ok
    end

    @tag :capture_log
    test "does not return a response with the given body", %{port: port} do
      parent_pid = self()
      path = 10 |> :crypto.strong_rand_bytes() |> Base.encode16(case: :lower)

      handler =
        quote do
          ws(unquote(path), fn "test", socket ->
            send(unquote(parent_pid), {:handler, "handler_received"})
            :noreply
          end)
        end

      bandit_opts = [port: port]
      mod = Support.RouteTester.generate_module(handler, bandit_opts: bandit_opts)

      {:ok, _} = start_supervised(mod)

      tester_pid =
        start_supervised!(
          {Support.WsTester, %{url: "ws://localhost:#{port}/#{path}", parent_pid: parent_pid}}
        )

      WebSockex.send_frame(tester_pid, {:text, "test"})
      assert_receive {:handler, "handler_received"}
      refute_receive :_, 500

      :ok
    end
  end

  describe "unmatched/1" do
    test "returns a response with the given body" do
      handler = quote do: unmatched(fn _ -> "test" end)

      mod = Support.RouteTester.generate_module(handler)
      response = Req.get!("/", plug: mod)

      assert response.body == "test"
      assert response.status == 404
    end
  end

  describe "plug usage" do
    test "uses given plug by given order" do
      handler =
        quote do: get("/", fn %{assigns: %{plug_assgined: plug_assgined}} -> plug_assgined end)

      plug1 = {Support.PlugTester, to_assign: "plug1"}
      plug2 = {Support.PlugTester, to_assign: "plug2"}

      mod = Support.RouteTester.generate_module(handler, plugs: [plug1, plug2])
      assert Req.get!("/", plug: mod).body == ["plug1", "plug2"]
    end
  end

  describe "non matching routes without unmatched handler" do
    test "returns an log error with the method and path of the failed route" do
      mod = Support.RouteTester.generate_module(quote do: get("/", fn _ -> "test" end))

      assert capture_log(fn -> Req.get!("/not_here", plug: mod) end) =~
               "Failed to match route: GET /not_here"
    end
  end

  describe "static configuration" do
    @describetag :tmp_dir

    setup %{tmp_dir: tmp_dir} do
      static_dir = Path.join(tmp_dir, "static")
      File.mkdir_p!(static_dir)

      css_path = Path.join(static_dir, "app.css")
      File.write!(css_path, "body { color: #333; }\n")

      on_exit(fn -> File.rm(css_path) end)
      %{static_dir: static_dir}
    end

    test "returns a static file", %{static_dir: static_dir} do
      handler = quote do: unmatched(fn _ -> "" end)

      mod =
        Support.RouteTester.generate_module(handler,
          static: [at: "/", from: static_dir]
        )

      assert Req.get!("/app.css", plug: mod).status == 200
    end

    test "returns a 404 for non-existing static file", %{static_dir: static_dir} do
      handler = quote do: unmatched(fn _ -> "" end)

      mod =
        Support.RouteTester.generate_module(handler,
          static: [at: "/", from: static_dir]
        )

      assert Req.get!("/not_found.txt", plug: mod).status == 404
    end
  end

  describe "error_handler option" do
    test "invokes custom error handler on error" do
      handler =
        quote do
          get("/", fn _ -> {:error, :fail} end)
        end

      defmodule ErrorHandler do
        import Plug.Conn
        def error(conn, {:error, :fail}), do: send_resp(conn, 502, "custom error")
      end

      mod = Support.RouteTester.generate_module(handler, error_handler: &ErrorHandler.error/2)

      response = Req.get!("/", plug: mod, retry: false)
      assert response.status == 502
      assert response.body == "custom error"
    end

    test "invokes default error handler on error" do
      handler =
        quote do
          get("/", fn _ -> {:error, :fail} end)
        end

      mod = Support.RouteTester.generate_module(handler)

      log =
        capture_log(fn ->
          response = Req.get!("/", plug: mod, retry: false)
          assert response.status == 500
          assert response.body == "Internal Server Error"
        end)

      assert log =~ "Unhandled error: {:error, :fail}"
    end

    test "handles exceptions with custom error handler" do
      handler =
        quote do
          get("/", fn _ -> raise "test exception" end)
        end

      defmodule CustomErrorHandler do
        import Plug.Conn

        def handle_errors(conn, _assigns) do
          send_resp(conn, 500, "Custom Error Handler: Exception occurred")
        end
      end

      mod =
        Support.RouteTester.generate_module(handler,
          error_handler: &CustomErrorHandler.handle_errors/2
        )

      response = Req.get!("/", plug: mod, retry: false)
      assert response.status == 500
      assert response.body == "Custom Error Handler: Exception occurred"
    end

    test "handles exceptions with default error handler" do
      handler =
        quote do
          get("/", fn _ -> raise "test exception" end)
        end

      mod = Support.RouteTester.generate_module(handler)

      log =
        capture_log(fn ->
          response = Req.get!("/", plug: mod, retry: false)

          assert response.status == 500
          assert response.body == "Internal Server Error"
        end)

      assert log =~ "Unhandled error: %RuntimeError{message: \"test exception\"}"
    end

    test "handles unmatched errors gracefully" do
      handler =
        quote do
          get("/", fn _ -> {:error, :fail} end)
        end

      defmodule ErrorHandler do
        import Plug.Conn
        def error(conn, {:error, :no_match}), do: send_resp(conn, 404, "custom not found error")
      end

      mod = Support.RouteTester.generate_module(handler, error_handler: &ErrorHandler.error/2)

      response = Req.get!("/", plug: mod, retry: false)
      assert response.status == 500
      assert response.body == "Internal Server Error"
    end
  end
end
