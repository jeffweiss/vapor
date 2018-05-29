defmodule Vapor.StorageTest do
  use ExUnit.Case, async: false

  alias Vapor.Storage

  test "can store configuration" do
    Storage.start_link()
    assert :ok = Storage.put([{:foo, 1}, {:bar, 3}, {:baz, 2}])
    assert {:ok, [{:foo, 1}, {:bar, 3}, {:baz, 2}]} = Storage.get()
  end
end
