defmodule Example do
  use Francis,
    plugs: [  Plug.Logger ],
    static: [ at: "/static", from: "priv/static" ]

  get("/", fn _ ->
    """
    <html>
     <body>
       <h1>Hello, world!</h1>
     </body>
    </html>
    """
  end)

  get("/name/:name", fn %{params: %{"name" => name}} -> "hello #{name}" end)
  get("/api/user", fn _ -> %{user: %{name: "Filipe Cabaço", github: "filipecabaco"}} end)
  ws("ws", fn "ping" -> "pong" end)
  unmatched(fn _ -> "not found" end)
end
