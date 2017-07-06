defmodule PlayerTest do
  use ExUnit.Case
  require StatemTest.Macro
  import StatemTest.Macro
  @moduledoc false

  setup do
    {:ok, tab: BeanGame.Mock.init()}
  end

  test "Player join game" do
    {:ok, _player1} = Player.start_link(:testPlayer)
    assert_state :waiting_to_start, for: :testPlayer
    :ok = Player.join_game(:testPlayer, :testGame)
    assert_state :no_turn, for: :testPlayer
    Player.stop(:testPlayer)
  end

  test "Player playing cards"  do
    {:ok, _player1} = Player.start_link(:testPlayer)
    :ok = Player.join_game(:testPlayer, :testGame)
    create_hand(:testPlayer)
    assert_state :no_turn, for: :testPlayer

    {:error, :illegal_move} = Player.play_card(:testPlayer, 1)
    Player.start_turn(:testPlayer)
    Player.skip_initial(:testPlayer)
    assert_state :play_cards, for: :testPlayer
    :ok = Player.play_card(:testPlayer, 1)
    assert_state :play_cards, for: :testPlayer
    :ok = Player.play_card(:testPlayer, 2)
    assert_state :discard, for: :testPlayer
    {:error, :illegal_move} = Player.play_card(:testPlayer, 1)

    Player.stop(:testPlayer)
  end

  test "Passing on playing cards" do
    {:ok, _player1} = Player.start_link(:testPlayer)
    :ok = Player.join_game(:testPlayer, :testGame)
    create_hand(:testPlayer)

    Player.start_turn(:testPlayer)
    Player.skip_initial(:testPlayer)
    assert_state :play_cards, for: :testPlayer
    {:error, :illegal_move} = Player.pass(:testPlayer)
    :ok = Player.play_card(:testPlayer, 1)
    assert_state :play_cards, for: :testPlayer
    :ok = Player.pass(:testPlayer)
    assert_state :discard, for: :testPlayer
    {:error, :illegal_move} = Player.play_card(:testPlayer, 1)

    Player.stop(:testPlayer)
  end

  test "Discarding" do
    {:ok, _player1} = Player.start_link(:testPlayer)
    :ok = Player.join_game(:testPlayer, :testGame)
    create_hand(:testPlayer)

    Player.start_turn(:testPlayer)
    Player.skip_initial(:testPlayer)
    assert_state :play_cards, for: :testPlayer
    :ok = Player.play_card(:testPlayer, 1)
    :ok = Player.play_card(:testPlayer, 2)
    assert_state :discard, for: :testPlayer
    :ok = Player.discard_card(:testPlayer, 1)
    assert_state :bonus_cards, for: :testPlayer

    Player.stop(:testPlayer)
  end

  test "Pass discarding" do
    {:ok, _player1} = Player.start_link(:testPlayer)
    :ok = Player.join_game(:testPlayer, :testGame)
    create_hand(:testPlayer)

    Player.start_turn(:testPlayer)
    Player.skip_initial(:testPlayer)
    assert_state :play_cards, for: :testPlayer
    :ok = Player.play_card(:testPlayer, 1)
    :ok = Player.play_card(:testPlayer, 2)
    assert_state :discard, for: :testPlayer
    :ok = Player.pass(:testPlayer)
    assert_state :bonus_cards, for: :testPlayer

    Player.stop(:testPlayer)
  end

  test "No cards in hand" do
    {:ok, _player1} = Player.start_link(:testPlayer)
    :ok = Player.join_game(:testPlayer, :testGame)

    Player.start_turn(:testPlayer)
    Player.skip_initial(:testPlayer)
    assert_state :bonus_cards, for: :testPlayer

    Player.stop(:testPlayer)
  end

  test "Play the only card" do
    {:ok, _player1} = Player.start_link(:testPlayer)
    :ok = Player.join_game(:testPlayer, :testGame)
    Player.deal_card(:testPlayer, %Beans.GreenBean{})

    Player.start_turn(:testPlayer)
    Player.skip_initial(:testPlayer)
    assert_state :play_cards, for: :testPlayer
    :ok = Player.play_card(:testPlayer, 1)
    assert_state :bonus_cards, for: :testPlayer

    Player.stop(:testPlayer)
  end

  test "Pick mid cards" do
    {:ok, _player1} = Player.start_link(:midTestPlayer)
    :ok = Player.join_game(:midTestPlayer, :testGame)
    Player.deal_card(:midTestPlayer, %Beans.GreenBean{})

    Player.start_turn(:midTestPlayer)
    Player.skip_initial(:midTestPlayer)
    assert_state :play_cards, for: :midTestPlayer
    :ok = Player.play_card(:midTestPlayer, 1)
    assert_state :bonus_cards, for: :midTestPlayer

    BeanGame.Mock.set_mid_cards(:testGame, [%Beans.GreenBean{}, %Beans.SoyBean{}, %Beans.GreenBean{}])
    :ok = Player.play_mid_card(:midTestPlayer, 0, 1)
    IO.puts inspect :ets.lookup(:testGameTable, :testGame)
    :ok = Player.play_mid_card(:midTestPlayer, 1, 1)
    :ok = Player.play_mid_card(:midTestPlayer, 0, 2)
    Player.end_turn(:midTestPlayer)
    assert_state :no_turn, for: :midTestPlayer

    Player.stop(:midTestPlayer)
  end

  test "Pick some mid cards" do
    {:ok, _player1} = Player.start_link(:midTestPlayer2)
    :ok = Player.join_game(:midTestPlayer2, :testGame)
    Player.deal_card(:midTestPlayer2, %Beans.GreenBean{})
    Player.start_turn(:midTestPlayer2)
    Player.skip_initial(:midTestPlayer2)
    assert_state :play_cards, for: :midTestPlayer2
    :ok = Player.play_card(:midTestPlayer2, 1)
    assert_state :bonus_cards, for: :midTestPlayer2

    BeanGame.Mock.set_mid_cards(:testGame, [%Beans.GreenBean{}, %Beans.SoyBean{}, %Beans.GreenBean{}])
    :ok = Player.play_mid_card(:midTestPlayer2, 0, 1)
    :ok = Player.pass(:midTestPlayer2)
    Player.end_turn(:midTestPlayer2)
    assert_state :no_turn, for: :midTestPlayer2

    Player.stop(:midTestPlayer2)
  end

  test "Take illegal card" do
    {:ok, _player1} = Player.start_link(:midTestPlayer3)
    :ok = Player.join_game(:midTestPlayer3, :testGame)
    Player.deal_card(:midTestPlayer3, for: %Beans.GreenBean{})
    Player.start_turn(:midTestPlayer3)
    Player.skip_initial(:midTestPlayer3)
    assert_state :play_cards, for: :midTestPlayer3
    :ok = Player.play_card(:midTestPlayer3, 1)
    assert_state :bonus_cards, for: :midTestPlayer3

    BeanGame.Mock.set_mid_cards(:testGame, [%Beans.GreenBean{}, %Beans.SoyBean{}, %Beans.GreenBean{}])
    {:error, :illegal_move} = Player.play_mid_card(:midTestPlayer3, 1, 1)
    :ok = Player.pass(:midTestPlayer3)
    Player.end_turn(:midTestPlayer3)
    assert_state :no_turn, for: :midTestPlayer3

    Player.stop(:midTestPlayer3)
  end

  defp create_hand(player) do
    Player.deal_card(player, %Beans.GreenBean{})
    Player.deal_card(player, %Beans.WaxBean{})
    Player.deal_card(player, %Beans.SoyBean{})
    Player.deal_card(player, %Beans.GreenBean{})
    Player.deal_card(player, %Beans.GreenBean{})
  end



end

