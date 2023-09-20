defmodule Example do
  import Plug.BasicAuth

  use Francis, plugs: [{:basic_auth, username: "test", password: "test"}]

  get("/", fn _ ->
    """
    <html>
     <body>
       <h1>Hello, world!</h1>
     </body>
    </html>
    """
  end)

  get("/:name", fn %{params: %{"name" => name}} -> "hello #{name}" end)

  get("/api/user", fn _ -> %{user: %{name: "Filipe Cabaço", github: "filipecabaco"}} end)

  ws("ws", fn "ping" -> "pong" end)

  unmatched(fn _ -> "not found" end)
end
