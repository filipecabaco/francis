defmodule Frank.MixProject do
  use Mix.Project

  def project do
    [
      app: :francis,
      version: "0.1.0-pre",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: [
        files: ["lib", "test", "mix.exs", "README*", "LICENSE*"],
        maintainers: ["Filipe Cabaço"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/filipecabaco/francis"}
      ],
      description:
        "A simple wrapper around Plug and Bandit to reduce boilerplate for simple APIs",
      source_url: "https://github.com/filipecabaco/francis"
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bandit, ">= 0.7.7"},
      {:jason, "~> 1.4"},
      {:websock, "~> 0.5"},
      {:websock_adapter, "~> 0.5.4"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
