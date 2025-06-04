defmodule Mix.Tasks.Francis.NewTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias Mix.Tasks.Francis.New
  @moduletag :tmp_dir

  test "creates a new project with default options", %{tmp_dir: tmp_dir} do
    File.cd!(tmp_dir, fn ->
      app_name = "my_app"

      assert capture_io(fn -> New.main([app_name]) end) =~ ""

      assert File.dir?(app_name)
      assert File.exists?(Path.join([app_name, "mix.exs"]))
      assert File.exists?(Path.join([app_name, ".gitignore"]))
      assert File.dir?(Path.join([app_name, "lib"]))
      assert File.exists?(Path.join([app_name, "lib", "#{app_name}.ex"]))

      # Check content
      mix_content = File.read!(Path.join([app_name, "mix.exs"]))
      assert mix_content =~ "defmodule MyApp.MixProject"
      assert mix_content =~ ":my_app"
    end)
  end

  test "creates a new project with supervisor option", %{tmp_dir: tmp_dir} do
    File.cd!(tmp_dir, fn ->
      app_name = "my_sup_app"

      assert capture_io(fn -> New.main([app_name, "--sup"]) end) =~ ""

      assert File.dir?(app_name)
      assert File.exists?(Path.join([app_name, "lib", "application.ex"]))
      assert File.exists?(Path.join([app_name, "lib", "router.ex"]))
      app_content = File.read!(Path.join([app_name, "lib", "application.ex"]))
      assert app_content =~ "use Application"
      router_content = File.read!(Path.join([app_name, "lib", "router.ex"]))
      assert router_content =~ "use Francis"
    end)
  end

  test "creates a new project with supervisor and custom module name", %{tmp_dir: tmp_dir} do
    File.cd!(tmp_dir, fn ->
      app_name = "my_sup_app2"
      custom_module = "CustomApp"

      assert capture_io(fn ->
               New.main([app_name, "--sup", custom_module])
             end) =~ ""

      assert File.dir?(app_name)
      assert File.exists?(Path.join([app_name, "lib", "application.ex"]))
      assert File.exists?(Path.join([app_name, "lib", "router.ex"]))
      app_content = File.read!(Path.join([app_name, "lib", "application.ex"]))
      assert app_content =~ "defmodule CustomApp do"
      assert app_content =~ "CustomApp.Router"
      router_content = File.read!(Path.join([app_name, "lib", "router.ex"]))
      assert router_content =~ "defmodule CustomApp.Router do"
    end)
  end

  test "raises if app already exists", %{tmp_dir: tmp_dir} do
    File.cd!(tmp_dir, fn ->
      app_name = "existing_app"
      File.mkdir_p!(app_name)

      assert_raise Mix.Error, ~r/already exists/, fn ->
        New.main([app_name])
      end
    end)
  end

  test "raises if app name is invalid", %{tmp_dir: tmp_dir} do
    File.cd!(tmp_dir, fn ->
      assert_raise Mix.Error, ~r/must only contain alphanumeric/, fn ->
        New.main(["bad-app!"])
      end
    end)
  end

  test "validate app name format rules",
       %{tmp_dir: tmp_dir} do
    File.cd!(tmp_dir, fn ->
      valid_names = [
        "foo",
        "foo_bar",
        "foo123",
        "FooBar",
        "F123",
        "foo_bar_123"
      ]

      invalid_names = [
        "1foo",
        "_foo",
        "foo-bar",
        "foo.bar",
        "foo bar",
        "foo!",
        "foo@bar",
        "foo-bar_baz",
        "foo/bar"
      ]

      Enum.each(valid_names, fn name ->
        # Should not raise
        Mix.Tasks.Francis.New.main([name])
        assert File.dir?(name)
      end)

      Enum.each(invalid_names, fn name ->
        assert_raise Mix.Error,
                     ~r/Application name must only contain alphanumeric characters and underscores/,
                     fn ->
                       Mix.Tasks.Francis.New.main([name])
                     end
      end)
    end)
  end
end
