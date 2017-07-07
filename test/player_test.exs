defmodule PlayerTest do
  use ExUnit.Case
  require StatemTest.Macro
  import StatemTest.Macro
  @moduledoc false

  setup_all do
    :ets.new(:testGameTable, [:set, :public, :named_table])
#    :meck.unload()
    :meck.new(BeanGame)
    :meck.expect(BeanGame, :register_player, fn (_,_) -> :ok end)
    :meck.expect(BeanGame, :discard_cards, fn (_,_) -> :ok end)
    :meck.expect(BeanGame, :get_mid_cards,   fn (gameName) ->
                                               case :ets.lookup(:testGameTable, gameName) do
                                                 [] -> []
                                                 [{^gameName, list}] -> list
                                               end
                                             end)
    :meck.expect(BeanGame, :new_mid_cards, fn (_) -> :ok end)
    :meck.expect(BeanGame, :get_mid_card,   fn (gameName, index) ->
                                              [{^gameName, list}] = :ets.lookup(:testGameTable, gameName)
                                                case Enum.at(list, index) do
                                                  nil -> {:error, :invalid_card}
                                                  elem -> {:ok, elem}
                                                end
                                            end)
    :meck.expect(BeanGame, :remove_mid_card,    fn (gameName, index) ->
                                                  [{^gameName, list}] = :ets.lookup(:testGameTable, gameName)
                                                  newList = List.delete_at(list, index)
                                                  :ets.insert(:testGameTable, {gameName, newList})
                                                  :ok
                                                end)
    :meck.expect(BeanGame, :player_done, fn (_) -> :ok end)
#    {:ok, tab: BeanGame.Mock.init()}
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
    Player.skip_mid_cards(:testPlayer)
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
    Player.skip_mid_cards(:testPlayer)
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
    Player.skip_mid_cards(:testPlayer)
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
    Player.skip_mid_cards(:testPlayer)
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
    Player.skip_mid_cards(:testPlayer)
    assert_state :bonus_cards, for: :testPlayer

    Player.stop(:testPlayer)
  end

  test "Play the only card" do
    {:ok, _player1} = Player.start_link(:testPlayer)
    :ok = Player.join_game(:testPlayer, :testGame)
    Player.deal_card(:testPlayer, %Beans.GreenBean{})

    Player.start_turn(:testPlayer)
    Player.skip_mid_cards(:testPlayer)
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
    Player.skip_mid_cards(:midTestPlayer)
    assert_state :play_cards, for: :midTestPlayer
    :ok = Player.play_card(:midTestPlayer, 1)
    assert_state :bonus_cards, for: :midTestPlayer

    set_mid_cards(:testGame, [%Beans.GreenBean{}, %Beans.SoyBean{}, %Beans.GreenBean{}])
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
    Player.skip_mid_cards(:midTestPlayer2)
    assert_state :play_cards, for: :midTestPlayer2
    :ok = Player.play_card(:midTestPlayer2, 1)
    assert_state :bonus_cards, for: :midTestPlayer2

    set_mid_cards(:testGame, [%Beans.GreenBean{}, %Beans.SoyBean{}, %Beans.GreenBean{}])
    :ok = Player.play_mid_card(:midTestPlayer2, 0, 1)
    :ok = Player.pass(:midTestPlayer2)
    Player.end_turn(:midTestPlayer2)
    assert_state :no_turn, for: :midTestPlayer2

    Player.stop(:midTestPlayer2)
  end

  test "Take illegal card" do
    {:ok, _player1} = Player.start_link(:midTestPlayer3)
    :ok = Player.join_game(:midTestPlayer3, :testGame)
    Player.deal_card(:midTestPlayer3, %Beans.GreenBean{})
    Player.start_turn(:midTestPlayer3)
    Player.skip_mid_cards(:midTestPlayer3)
    assert_state :play_cards, for: :midTestPlayer3
    :ok = Player.play_card(:midTestPlayer3, 1)
    assert_state :bonus_cards, for: :midTestPlayer3

    set_mid_cards(:testGame, [%Beans.GreenBean{}, %Beans.SoyBean{}, %Beans.GreenBean{}])
    {:error, :illegal_move} = Player.play_mid_card(:midTestPlayer3, 1, 1)
    :ok = Player.pass(:midTestPlayer3)
    Player.end_turn(:midTestPlayer3)
    assert_state :no_turn, for: :midTestPlayer3

    Player.stop(:midTestPlayer3)
  end

  test "Initial cards" do
    {:ok, _player1} = Player.start_link(:initTestPlayer)
    :ok = Player.join_game(:initTestPlayer, :testGame)
    Player.deal_card(:initTestPlayer, %Beans.GreenBean{})
    Player.start_turn(:initTestPlayer)
    assert_state :initial_cards, for: :initTestPlayer
    set_mid_cards(:testGame, [%Beans.GreenBean{}, %Beans.SoyBean{}])
    :ok = Player.play_mid_card(:initTestPlayer, 0, 1)
    :ok = Player.play_mid_card(:initTestPlayer, 0, 2)
    Player.skip_mid_cards(:initTestPlayer)
    assert_state :play_cards, for: :initTestPlayer

    Player.stop(:initTestPlayer)
  end

  test "Discard an initial card" do
    {:ok, _player1} = Player.start_link(:initTestPlayer2)
    :ok = Player.join_game(:initTestPlayer2, :testGame)
    Player.deal_card(:initTestPlayer2, %Beans.GreenBean{})
    Player.start_turn(:initTestPlayer2)
    assert_state :initial_cards, for: :initTestPlayer2
    set_mid_cards(:testGame, [%Beans.GreenBean{}, %Beans.SoyBean{}])
    :ok = Player.play_mid_card(:initTestPlayer2, 0, 1)
    {:error, :illegal_move} = Player.play_mid_card(:initTestPlayer2, 0, 1)
    :ok = Player.discard_mid_card(:initTestPlayer2, 0)
    Player.skip_mid_cards(:initTestPlayer2)
    assert_state :play_cards, for: :initTestPlayer2

    Player.stop(:initTestPlayer2)
  end

  test "Skip initial cards" do
    {:ok, _player1} = Player.start_link(:initTestPlayer3)
    :ok = Player.join_game(:initTestPlayer3, :testGame)
    Player.deal_card(:initTestPlayer3, %Beans.GreenBean{})
    Player.start_turn(:initTestPlayer3)
    assert_state :initial_cards, for: :initTestPlayer3
    set_mid_cards(:testGame, [%Beans.GreenBean{}, %Beans.SoyBean{}])
    :ok = Player.pass(:initTestPlayer3)
    assert_state :play_cards, for: :initTestPlayer3

    Player.stop(:initTestPlayer3)
  end

  test "Scoring" do
    {:ok, _player1} = Player.start_link(:scorePlayer)
    :ok = Player.join_game(:scorePlayer, :testGame)
    Player.deal_card(:scorePlayer, %Beans.GreenBean{})
    Player.deal_card(:scorePlayer, %Beans.WaxBean{})
    Player.start_turn(:scorePlayer)
    assert_state :initial_cards, for: :scorePlayer
    set_mid_cards(:testGame, [%Beans.GreenBean{}, %Beans.GreenBean{}, %Beans.GreenBean{}])
    :ok = Player.play_mid_card(:scorePlayer, 0, 1)
    :ok = Player.play_mid_card(:scorePlayer, 0, 1)
    :ok = Player.play_mid_card(:scorePlayer, 0, 1)
    Player.skip_mid_cards(:scorePlayer)
    Player.play_card(:scorePlayer, 1)
    Player.harvest(:scorePlayer, 1)
    Player.play_card(:scorePlayer, 1)
    :ok = Player.pass(:scorePlayer)
    1 = Player.end_game(:scorePlayer)
  end

  test "Third field" do
    {:ok, _player1} = Player.start_link(:thirdFieldPlayer)
    :ok = Player.join_game(:thirdFieldPlayer, :testGame)
    Player.deal_card(:thirdFieldPlayer, %Beans.RedBean{})
    Player.deal_card(:thirdFieldPlayer, %Beans.WaxBean{})
    Player.start_turn(:thirdFieldPlayer)
    {:error, :illegal_move} = Player.purchase_third_field(:thirdFieldPlayer)

    set_mid_cards(:testGame, [%Beans.RedBean{}, %Beans.RedBean{}, %Beans.RedBean{}])
    :ok = Player.play_mid_card(:thirdFieldPlayer, 0, 1)
    :ok = Player.play_mid_card(:thirdFieldPlayer, 0, 1)
    :ok = Player.play_mid_card(:thirdFieldPlayer, 0, 1)
    Player.skip_mid_cards(:thirdFieldPlayer)
    Player.play_card(:thirdFieldPlayer, 1)
    Player.harvest(:thirdFieldPlayer, 1)
    :ok = Player.purchase_third_field(:thirdFieldPlayer)
    :ok = Player.play_card(:thirdFieldPlayer, 3)

    Player.stop(:thirdFieldPlayer)
  end

  defp create_hand(player) do
    Player.deal_card(player, %Beans.GreenBean{})
    Player.deal_card(player, %Beans.WaxBean{})
    Player.deal_card(player, %Beans.SoyBean{})
    Player.deal_card(player, %Beans.GreenBean{})
    Player.deal_card(player, %Beans.GreenBean{})
  end

  defp set_mid_cards(gameName, list) do
    :ets.insert(:testGameTable, {gameName, list})
  end


end

