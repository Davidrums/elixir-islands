defmodule RulesTest do
  use ExUnit.Case
  alias IslandsEngine.Rules
  
  test "rules should start as initialized" do
    rules = Rules.new()
    assert rules.state == :initialized
  end
  
  test "rules should only be able to add players from initialized state" do
    rules = Rules.new()
    {:ok, correct} = rules
    |> Rules.check(:add_player)
    :error =  rules
    |> Rules.check({:position_islands, :player2})
    
    assert correct.state == :players_set
  end
  
end
