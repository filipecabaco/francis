defmodule Mix.Tasks.Francis.New do
  use Mix.Task

  @shortdoc "Generates a new Francis project"

  @moduledoc """
  Generates a new Francis project.
  This task creates a new directory with the specified application name and a basic project structure.

  ## Usage

      mix francis.new <app_name> [--sup] [<supervisor_module_name>]

  ## Examples

      mix francis.new my_app
      mix francis.new my_app --sup
      mix francis.new my_app --sup MyApp
  """
  def usage, do: @moduledoc

  def main(args) do
    case run(args) do
      :ok -> :ok
      {:error, reason} -> Mix.raise("Error: #{reason}")
    end
  end

  def run([]) do
    Mix.raise("You must provide an application name, e.g. `mix francis.new my_app`")
  end

  def run([app_name | opts]) do
    if app_name =~ ~r/[^a-zA-Z0-9_]/ do
      Mix.raise("Application name must only contain alphanumeric characters and underscores")
    end

    if File.exists?(app_name) do
      Mix.raise("Directory `#{app_name}` already exists. Please choose a different name.")
    end

    {sup, supervisor_module_name} =
      OptionParser.parse!(opts, strict: [sup: :boolean, supervisor_module_name: :string])

    Mix.Generator.create_directory(app_name)
    root = Path.expand("../../tasks/francis", __DIR__)

    module_name =
      if supervisor_module_name == [],
        do: app_name,
        else: hd(supervisor_module_name)

    Mix.Generator.copy_template(
      "#{root}/new/mix.eex",
      "#{app_name}/mix.exs",
      %{module_name: module_name, app_name: app_name}
    )

    Mix.Generator.copy_template(
      "#{root}/new/.gitignore",
      "#{app_name}/.gitignore",
      %{}
    )

    if sup != [] && hd(sup) do
      Mix.Generator.copy_template(
        "#{root}/new/with_supervisor/application.eex",
        "#{app_name}/lib/application.ex",
        %{module_name: module_name}
      )

      Mix.Generator.copy_template(
        "#{root}/new/with_supervisor/router.eex",
        "#{app_name}/lib/router.ex",
        %{module_name: module_name}
      )
    else
      Mix.Generator.copy_template(
        "#{root}/new/without_supervisor/application.eex",
        "#{app_name}/lib/#{app_name}.ex",
        %{module_name: module_name}
      )
    end
  end
end
