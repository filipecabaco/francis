defmodule Mix.Tasks.Francis.ReleaseTest do
  # These tests need to run synchronously because they rely on the current working directory.
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Francis.Release

  @tmp_dir Path.join(System.tmp_dir!(), "francis_release_test")
  @dockerfile Path.join(@tmp_dir, "Dockerfile")
  @dockerignore Path.join(@tmp_dir, ".dockerignore")

  setup do
    File.rm_rf!(@tmp_dir)
    File.mkdir_p!(@tmp_dir)
    cwd = File.cwd!()
    File.cd!(@tmp_dir)

    on_exit(fn ->
      File.cd!(cwd)
      File.rm_rf!(@tmp_dir)
    end)

    :ok
  end

  test "generates Dockerfile and .dockerignore with default options" do
    assert capture_io(fn ->
             Release.run([])
           end) =~ ""

    assert File.exists?(@dockerfile)
    assert File.exists?(@dockerignore)
    dockerfile = File.read!(@dockerfile)
    assert dockerfile =~ "EXPOSE 4000"
    assert dockerfile =~ "mix release"
    assert dockerfile =~ "CMD [\"bin/francis\", \"start\"]"
    dockerignore = File.read!(@dockerignore)
    assert dockerignore =~ ".git"
    assert dockerignore =~ "_build"
  end

  test "generates Dockerfile with custom port" do
    assert capture_io(fn ->
             Release.run(["--port", "1234"])
           end) =~ ""

    dockerfile = File.read!(@dockerfile)
    assert dockerfile =~ "EXPOSE 1234"
  end

  test "generates Dockerfile with custom port using alias" do
    assert capture_io(fn ->
             Release.run(["-p", "5678"])
           end) =~ ""

    dockerfile = File.read!(@dockerfile)
    assert dockerfile =~ "EXPOSE 5678"
  end

  test "does not raise on unknown options and ignores them" do
    assert capture_io(fn ->
             Release.run(["--unknown", "foo"])
           end) =~ ""

    assert File.exists?(@dockerfile)
    assert File.exists?(@dockerignore)
  end
end
