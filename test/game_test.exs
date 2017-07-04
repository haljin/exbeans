defmodule GameTest do
  use ExUnit.Case
  @moduledoc false

  test "GameBoard" do
    {:ok, pid} = BeanGame.start_link(:testGame)
    ^pid = Process.whereis(:testGame)
    assert Process.alive?(pid)
  end

  test "Players join" do
    {:ok, _pid} = BeanGame.start_link(:testGame)
    {:ok, _player1} = Player.start_link(:pawel)
    {:ok, _player2} = Player.start_link(:not_pawel)

    :ok = Player.join_game(:pawel, :testGame)
    :ok = Player.join_game(:not_pawel, :testGame)

    hand1 = Player.get_hand(:pawel)
    hand2 = Player.get_hand(:not_pawel)

    assert length(hand1) == 5
    assert length(hand2) == 5
  end
end