defmodule ExampleTest do
  use ExUnit.Case

  test "index returns valid html" do
    html = Req.get!("/", plug: Example).body
    assert {:ok, _html_tree} = Floki.parse_document(html)
  end

  test "greets the world" do
    assert Req.get!("/world", plug: Example).body == "hello world"
  end
end
