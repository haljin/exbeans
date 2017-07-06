defmodule PlayerTest do
  use ExUnit.Case
  import Mock
  @moduledoc false

  test "Player join game" do
    {:ok, _player1} = Player.start_link(:testPlayer)
    with_mock BeanGame, [register_player: fn(_name, _player) -> :ok end] do
        :ok = Player.join_game(:testPlayer, :testGame)
    end
    Player.stop(:testPlayer)
  end

  test_with_mock "Player playing cards",
                 BeanGame, [register_player: fn(_name, _player) -> :ok end,
                            get_mid_cards: fn(_) -> [] end] do
    {:ok, _player1} = Player.start_link(:testPlayer)
    :ok = Player.join_game(:testPlayer, :testGame)
    create_hand()

    {:error, :illegal_move} = Player.play_card(:testPlayer, 1)
    Player.start_turn(:testPlayer)
    :ok = Player.play_card(:testPlayer, 1)
    :ok = Player.play_card(:testPlayer, 2)
    {:error, :illegal_move} = Player.play_card(:testPlayer, 1)

    Player.stop(:testPlayer)
  end

  test_with_mock "Passing on playing cards",
                 BeanGame, [register_player: fn(_name, _player) -> :ok end,
                            get_mid_cards: fn(_) -> [] end] do
    {:ok, _player1} = Player.start_link(:testPlayer)
    :ok = Player.join_game(:testPlayer, :testGame)
    create_hand()

    Player.start_turn(:testPlayer)
    {:error, :illegal_move} = Player.pass(:testPlayer)
    :ok = Player.play_card(:testPlayer, 1)
    :ok = Player.pass(:testPlayer)
    {:error, :illegal_move} = Player.play_card(:testPlayer, 1)

    Player.stop(:testPlayer)
  end

  defp create_hand() do
    Player.deal_card(:testPlayer, %Beans.GreenBean{})
    Player.deal_card(:testPlayer, %Beans.WaxBean{})
    Player.deal_card(:testPlayer, %Beans.SoyBean{})
    Player.deal_card(:testPlayer, %Beans.GreenBean{})
    Player.deal_card(:testPlayer, %Beans.GreenBean{})

  end

end