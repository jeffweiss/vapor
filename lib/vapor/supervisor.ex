defmodule Vapor.Supervisor do
  use Supervisor

  def start_link(args, opts) do
    Supervisor.start_link(__MODULE__, config, opts)
  end

  @impl true
  def init(config) do
    children = [
      {Vapor.Storage, 
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
