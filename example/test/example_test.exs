defmodule ExampleTest do
  use ExUnit.Case

  test "index returns valid html" do
    html = Req.get!("/", plug: Example).body
    assert {:ok, _html_tree} = Floki.parse_document(html)
  end

  test "greets the world" do
    assert Req.get!("/world", plug: Example).body == "hello world"
  end

  test "receives valid JSON" do
    assert Req.get!("/api/user", plug: Example).body == %{
             "user" => %{"name" => "Filipe Cabaço", "github" => "filipecabaco"}
           }
  end
end
