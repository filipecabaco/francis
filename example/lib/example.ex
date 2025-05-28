defmodule Example do
  use Francis,
    static: [at: "/static", from: "priv/static"]

  get("/", fn
    %{params: %{"name" => name}} ->
      """
      <!DOCTYPE html>
      <html>
      <head><title>Francis</title></head>
      <body><h1>Hello, #{name}!</h1></body>
      </html>
      """

    _params ->
      """
      <!DOCTYPE html>
      <html>
      <head><title>Francis</title></head>
      <body><h1>Hello, World!</h1></body>
      </html>
      """
  end)

  ws(
    "/ws",
    fn msg, conn ->
      Process.send_after(conn.transport, "sending back", 1000)
      {:reply, "received: #{msg}"}
    end,
    timeout: 1000
  )

  get("/:name", fn %{params: %{"name" => name}} -> "hello #{name}" end)
  post("/", fn conn -> conn.body_params end)

  unmatched(fn _ -> "not found" end)
end
