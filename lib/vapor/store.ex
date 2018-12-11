defmodule Vapor.Store do
  use GenServer

  @moduledoc """
    Module that loads config
    Attempts to load the config 10 times before returning :error
  """

  def start_link({module, plans}) do
    GenServer.start_link(__MODULE__, {module, plans}, name: module)
  end

  def init({module, plans}) do
    ^module = :ets.new(module, [:set, :protected, :named_table])

    case load_all_configs(plans) do
      :error ->
        {:stop, :could_not_load_config}
      fogs ->
        fogs
        |> condense_pool
        |> write_config(module)
        {:ok, %{plans: plans, fogs: [fogs], table: module}}
    end
  end

  def handle_call({:set, key, value}, _from, %{table: tab} = state) do
    current =
      case :ets.lookup(tab, key) do
        [{^key, [{:manual, _prior}|other_configs]}] -> other_configs
        [{^key, current}] -> current
        _ -> []
      end
    :ets.insert(tab, {key, [{:manual, value}|current]})

    {:reply, {:ok, value}, state}
  end

  def handle_call({:watched_notification, {source, updated}}, _from, %{fogs: [most_recent|_] = fogs, table: tab} = state) do
    new_fog = Keyword.replace!(most_recent, source, updated)
    new_fog
    |> condense_pool
    |> write_config(tab)
    {:reply, :ok, Map.put(state, :fogs, [new_fog|fogs])}
  end

  defp pathify_keys(map) when is_map(map) do
    map
    |> pathify_keys([], [])
    |> Enum.into(%{})
  end

  defp pathify_keys(map, path_so_far, completed_keys) do
    Enum.reduce(map, completed_keys, fn
      {k, v}, acc when is_map(v) ->
        pathify_keys(v, [k | path_so_far], acc)

      {k, v}, acc when is_list(k) ->
        [{k, v} | acc]

      {k, v}, acc ->
        [{Enum.reverse([k | path_so_far]), v} | acc]
    end)
  end

  def load_all_configs(plans) do
    config_values =
      plans
      |> Task.async_stream(&load_fog/1)
      |> Enum.to_list

    case Enum.any?(config_values, &( &1 == :error)) do
      true ->
        :error
      _ ->
        config_values
        |> Enum.map(&elem(&1, 1))
    end

  end

  def condense_pool(list_of_fogs) do
    case Enum.any?(list_of_fogs, &( &1 == :error)) do
      true ->
        :error
      _ ->
        list_of_fogs
        |> Enum.map(fn {source, fog} -> {source, pathify_keys(fog)} end)
        |> Enum.reduce(%{}, fn {source, fog}, acc ->
          Enum.reduce(fog, acc, fn {k, v}, acc ->
            Map.update(acc, k, [{source, v}], fn current -> [{source, v}|current] end)
          end)
        end)
    end
  end

  def load_fog(plan, retry_count \\ 0)
  def load_fog(_plan, 10), do: :error
  def load_fog(plan, retry_count) do
    case Vapor.Provider.load(plan) do
      {:ok, fog} ->
        {Vapor.Provider.source_name(plan), fog}

      {:error, _e} ->
        load_fog(plan, retry_count + 1)
    end
  end

  defp load_config(table, plans, retry_count \\ 0)
  defp load_config(_table, [], _), do: :ok
  defp load_config(_table, _, 10), do: :error

  defp load_config(table, [plan | rest], retry_count) do
    case Vapor.Provider.load(plan) do
      {:ok, configs} ->
        configs
        |> pathify_keys
        |> Enum.each(fn k_v ->
          :ets.insert(table, k_v)
        end)

        load_config(table, rest, 0)

      {:error, _e} ->
        load_config(table, [plan | rest], retry_count + 1)
    end
  end

  defp write_config(configs, table) do
    Enum.each(configs, fn k_v ->
      :ets.insert(table, k_v)
    end)
  end
end
