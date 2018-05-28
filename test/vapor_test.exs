defmodule VaporTest do
  use ExUnit.Case, async: true
  doctest Vapor

  defmodule FakeConfig do
    use Vapor

    def start_link(files) do
      opts = [
        config_paths: files
      ]
      Vapor.start_link(__MODULE__, opts, name: FakeConfig)
    end
  end

  test "modules that use Config can be started" do
    opts = []
    {:ok, pid} = Vapor.start_link(FakeConfig, opts, name: FakeConfig)
    assert pid == Process.whereis(FakeConfig)
  end

  test "file sources are read in when the Config is started" do
    files = [
      "test/fixtures/config.json",
    ]
    FakeConfig.start_link(files)
    assert FakeConfig.get_int("app.port") == 1234
  end
end
