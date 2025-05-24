defmodule Example do
  use Francis,
    static: [at: "/static", from: "priv/static"]

  ws(
    "/ws",
    fn msg, conn ->
      Process.send_after(conn.transport, "sending back", 1000)
      "received: #{msg}"
    end,
    timeout: 1000
  )

  get("/:name", fn %{params: %{"name" => name}} -> "hello #{name}" end)
  post("/", fn conn -> conn.body_params end)

  unmatched(fn _ -> "not found" end)
end
