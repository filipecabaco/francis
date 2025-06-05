Mix.install([:req])

total =
  Req.get!("https://registry.hub.docker.com/v2/repositories/hexpm/elixir/tags?page_size=1")
  |> then(& &1.body["count"])

IO.inspect(total, label: "Total Docker Tags")

images =
  for page <- 0..div(total, 100), reduce: [] do
    acc ->
      IO.puts("Fetching page #{page} of #{div(total, 100)}")

      names =
        Req.get!(
          "https://registry.hub.docker.com/v2/repositories/hexpm/elixir/tags?page=#{page}&page_size=100"
        )
        |> then(& &1.body["results"])
        |> Enum.map(& &1["name"])

      acc ++ names
  end

images =
  images
  |> Enum.filter(&String.contains?(&1, "bookworm"))
  |> Enum.uniq()
  |> Enum.sort()
  |> Enum.join("\n")

File.write!("docker_versions.txt", images)
