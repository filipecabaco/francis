defmodule ReadmeTest do
  use ExUnit.Case, async: true

  @app Mix.Project.config()[:app]

  test "version in README.md always matches the current #{@app} version" do
    assert File.read!(Path.join(__DIR__, "../README.md")) =~
             ~s'{:#{@app}, "~> #{Mix.Project.config()[:version]}"}'
  end
end
