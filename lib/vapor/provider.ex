defprotocol Vapor.Provider do
  @doc """
  Loads a configuration plan.
  """
  @spec load(any()) ::
          {:ok, %{optional(String.t()) => term()}}
          | {:error, term()}
  def load(plan)

  @doc """
  Returns an atom representing the source for a plan

  ## Examples
    iex> Vapor.Provider.source_name(Vapor.Config.Env.with_prefix("APP"))
    :env
    iex> Vapor.Provider.source_name(Vapor.Config.File.with_name("support/settings.json"))
    :file
  """
  @spec source_name(any()) :: atom()
  def source_name(plan)
end
