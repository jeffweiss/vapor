defmodule Vapor do
  @moduledoc """
  Documentation for Vapor.
  """

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour GenServer

      @doc false
      def init(config) do
        {:ok, config}
      end

      @doc false
      def handle_change(_source, old_config, new_config) do
        {:ok, new_config}
      end

      @doc false
      def handle_call(msg, _from, state) do
        # We do this to trick Dialyzer to not complain about non-local returns.
        reason = {:bad_call, msg}
        case :erlang.phash2(1, 1) do
          0 -> exit(reason)
          1 -> {:stop, reason, state}
        end
      end

      @doc false
      def handle_cast(msg, state) do
        # We do this to trick Dialyzer to not complain about non-local returns.
        reason = {:bad_cast, msg}
        case :erlang.phash2(1, 1) do
          0 -> exit(reason)
          1 -> {:stop, reason, state}
        end
      end

      @doc false
      def handle_info(_msg, state) do
        {:noreply, state}
      end

      @doc false
      def terminate(_reason, _state) do
        :ok
      end

      @doc false
      def code_change(_old_version, state, _extra) do
        {:ok, state}
      end

      def get_int(key) do
        Vapor.Config.get_int(config(), key)
      end

      defp config do
        :ets.tab2list(__MODULE__)
      end

      defoverridable [
        init: 1,
        handle_change: 3,

        handle_call: 3, handle_cast: 2, handle_info: 2,
        terminate: 2, code_change: 3
      ]
    end
  end

  def start_link(module, args, opts) do
    config =
      args
      |> fetch_config

    GenServer.start_link(module, config, opts)
  end

  defp fetch_config(args) do
    args
  end
end
