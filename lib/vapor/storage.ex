defmodule Vapor.Storage do
  use GenServer

  def start_link(args \\ []) do
    name = Keyword.fetch(args, :name)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  def put(config) do
    GenServer.call(__MODULE__, {:put, config})
  end

  def get do
    [{"config", config}] = :ets.tab2list(__MODULE__)
    {:ok, config}
  end

  def init([]) do
    __MODULE__ = :ets.new(__MODULE__, [:set, :named_table, :protected])
    {:ok, __MODULE__}
  end

  def handle_call({:put, config}, _from, table) do
    case :ets.insert(table, {"config", config}) do
      true ->
        {:reply, :ok, table}

      _ ->
        {:reply, :error, table}
    end
  end
end
