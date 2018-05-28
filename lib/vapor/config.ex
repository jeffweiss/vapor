defmodule Vapor.Config do

  def get_int(config, key) do
    config
    |> get(key)
    |> to_int
  end

  defp get(config, key) do
  end

  defp to_int(value) when is_binary(value), do: Integer.parse(value)
  defp to_int(_), do: :error
end
