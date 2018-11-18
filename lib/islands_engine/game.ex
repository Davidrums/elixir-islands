defmodule IslandsEngine.Game do
  alias __MODULE__
  alias IslandsEngine.Game.Server
  @players [:player1, :player2]
  
  def start_game(name), do: 
    Supervisor.start_child(IslandsEngine.Game.Supervisor, [name])
    
  def stop_game(name), do: 
    Supervisor.terminate_child(IslandsEngine.Game.Supervisor, Server.pid_from_name(name))
  
  def add_player(game, name) when is_binary(name), do: 
    GenServer.call(game, {:add_player, name})
  
  def position(game, player, key, row, col) when player in @players, do: 
    GenServer.call(game, {:position_island, player, key, row, col})
  
  def set_islands(game, player) when player in @players, do: 
    GenServer.call(game, {:set_islands, player})
  
  def guess_island(game, player, row, col) when player in @players, do: 
    GenServer.call(game, {:guess_coordinate, player, row, col})
  
end
