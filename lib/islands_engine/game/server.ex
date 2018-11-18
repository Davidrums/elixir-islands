defmodule IslandsEngine.Game.Server do
  use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient
  alias IslandsEngine.{Board, Guesses, Rules, Coordinate, Island}
  
  @timeout 60 * 60 * 14 * 1000
  
  def start_link(name) when is_binary(name), do: 
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  
  def init(name) do
    player1 = %{name: name, board: Board.new(), guesses: Guesses.new()}
    player2 = %{name: nil,  board: Board.new(), guesses: Guesses.new()}
    {:ok, %{player1: player1, player2: player2, rules: %Rules{}}, @timeout}
  end
  
  def handle_info(:timeout, state) do
    {:stop, {:shutdown, :timeout}, state}
  end
  
  def handle_call({:add_player, name}, _from, state_data) do
    with {:ok, rules} <- Rules.check(state_data.rules, :add_player)
    do
      state_data
      |> update_player2_name(name)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error -> {:reply, :error, state_data}
    end
  end
  
  def handle_call({:position_island, player, key, row, col}, _from, state) do
    board = player_board(state, player)
    with {:ok, rules} <- Rules.check(state.rules, {:position_islands, player}),
      {:ok, coordinate} <- Coordinate.new(row, col),
      {:ok, island} <- Island.new(key, coordinate),
      %{} = board <- Board.position_island(board, key, island)
    do
      state
      |> update_board(player, board)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error -> {:reply, :error, state}
      {:error, :invalid_coordinate} -> {:reply, {:error, :invalid_coordinate}, state}
      {:error, :invalid_island_type} -> {:reply, {:error, :invalid_island_type}, state}
    end
  end
  
  def handle_call({:set_islands, player}, _from, state) do
    board = player_board(state, player)
    with {:ok, rules} <- Rules.check(state.rules, {:set_islands, player}),
         true         <- Board.all_islands_positioned?(board)
    do
      state
      |> update_rules(rules)
      |> reply_success({:ok, board})
    else
      :error -> {:reply, :error, state}
      false  -> {:reply, {:error, :not_all_islands_positioned}, state}
    end
  end
  
  def handle_call({:guess_coordinate, player, row, col}, _from, state) do
    opponent = opponent(player)
    opponent_board = player_board(state, opponent)
    with {:ok, rules}      <- Rules.check(state.rules, {:guess_coordinate, player}),
         {:ok, coordinate} <- Coordinate.new(row,col),
         {hit_or_miss, forested_island, win_status, opponent_board} <- Board.guess(opponent_board, coordinate),
         {:ok, rules}      <- Rules.check(rules, {:win_check, win_status})
    do
      state
      |> update_board(opponent, opponent_board)
      |> update_guesses(player, hit_or_miss, coordinate)
      |> update_rules(rules)
      |> reply_success({hit_or_miss, forested_island, win_status})
    else
      :error -> {:reply, :invalid_coordinate}
      {:error, :invalid_coordinate} -> {:reply, {:error, :invalid_coordinate}, state}
    end
  end
  
  def pid_from_name(name) do
    name
    |> via_tuple()
    |> GenServer.whereis()
  end
  
  defp update_player2_name(state_data, name), do: put_in(state_data.player2.name, name)
  defp update_rules(state_data, rules), do: %{state_data | rules: rules}
  defp update_board(state, player, board), do: Map.update!(state, player, fn player -> %{player | board: board} end)
  defp update_guesses(state, player, hit_or_miss, coordinate) do
    update_in(state[player].guesses, fn guesses ->
      Guesses.add(guesses, hit_or_miss, coordinate)
    end)
  end
  
  defp reply_success(state_data, reply), do: {:reply, reply, state_data, @timeout}

  defp player_board(state, player), do: Map.get(state, player).board  
  defp opponent(:player1), do: :player2
  defp opponent(:player2), do: :player1
  
  defp via_tuple(name), do: {:via, Registry, {Registry.Game, name}}
end
