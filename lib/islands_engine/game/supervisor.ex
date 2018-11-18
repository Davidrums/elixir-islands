defmodule IslandsEngine.Game.Supervisor do
  use Elixir.Supervisor
  
  
  def start_link(_options), do: Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  
  def init(:ok), do: Supervisor.init([IslandsEngine.Game.Server], strategy: :simple_one_for_one)
end
