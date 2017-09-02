defmodule PlayerTest do
  use ExUnit.Case
  require StatemTest.Macro
  import StatemTest.Macro
  
  alias ExBeans.Player
  alias ExBeans.Beans
  alias ExBeans.BeanGame

  @moduledoc false

  setup_all do
    :ets.new(:testGameTable, [:set, :public, :named_table])
#    :meck.unload()
    :meck.new(BeanGame)
    :meck.expect(BeanGame, :register_player, fn (_,_,_) -> :ok end)
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
    {:ok, player1} = Player.start_link(:testPlayer)
    assert_state :waiting_to_start, for: player1
    :ok = Player.join_game(player1, :testGame)
    Player.stop(player1)
  end

  test "Player playing cards"  do
    {:ok, player1} = Player.start_link(:testPlayer)
    :ok = Player.join_game(player1, :testGame)
    Player.start_game(player1)
    create_hand(player1)
    assert_state :no_turn, for: player1

    {:error, :illegal_move} = Player.play_card(player1, 1)
    Player.start_turn(player1)
    Player.skip_mid_cards(player1)
    assert_state :play_cards, for: player1
    :ok = Player.play_card(player1, 1)
    assert_state :play_cards, for: player1
    :ok = Player.play_card(player1, 2)
    assert_state :discard, for: player1
    {:error, :illegal_move} = Player.play_card(player1, 1)

    Player.stop(player1)
  end

  test "Passing on playing cards" do
    {:ok, player1} = Player.start_link(:testPlayer)
    :ok = Player.join_game(player1, :testGame)
    Player.start_game(player1)
    create_hand(player1)

    Player.start_turn(player1)
    Player.skip_mid_cards(player1)
    assert_state :play_cards, for: player1
    {:error, :illegal_move} = Player.pass(player1)
    :ok = Player.play_card(player1, 1)
    assert_state :play_cards, for: player1
    :ok = Player.pass(player1)
    assert_state :discard, for: player1
    {:error, :illegal_move} = Player.play_card(player1, 1)

    Player.stop(player1)
  end

  test "Discarding" do
    {:ok, player1} = Player.start_link(:testPlayer)
    :ok = Player.join_game(player1, :testGame)
    Player.start_game(player1)
    create_hand(player1)

    Player.start_turn(player1)
    Player.skip_mid_cards(player1)
    assert_state :play_cards, for: player1
    :ok = Player.play_card(player1, 1)
    :ok = Player.play_card(player1, 2)
    assert_state :discard, for: player1
    :ok = Player.discard_card(player1, 1)
    assert_state :bonus_cards, for: player1

    Player.stop(player1)
  end

  test "Pass discarding" do
    {:ok, player1} = Player.start_link(:testPlayer)
    :ok = Player.join_game(player1, :testGame)
    Player.start_game(player1)
    create_hand(player1)

    Player.start_turn(player1)
    Player.skip_mid_cards(player1)
    assert_state :play_cards, for: player1
    :ok = Player.play_card(player1, 1)
    :ok = Player.play_card(player1, 2)
    assert_state :discard, for: player1
    :ok = Player.pass(player1)
    assert_state :bonus_cards, for: player1

    Player.stop(player1)
  end

  test "No cards in hand" do
    {:ok, player1} = Player.start_link(:testPlayer)
    :ok = Player.join_game(player1, :testGame)
    Player.start_game(player1)

    Player.start_turn(player1)
    Player.skip_mid_cards(player1)
    assert_state :bonus_cards, for: player1

    Player.stop(player1)
  end

  test "Play the only card" do
    {:ok, player1} = Player.start_link(:testPlayer)
    :ok = Player.join_game(player1, :testGame)
    Player.deal_card(player1, %Beans.GreenBean{})
    Player.start_game(player1)

    Player.start_turn(player1)
    Player.skip_mid_cards(player1)
    assert_state :play_cards, for: player1
    :ok = Player.play_card(player1, 1)
    assert_state :bonus_cards, for: player1

    Player.stop(player1)
  end

  test "Pick mid cards" do
    {:ok, player1} = Player.start_link(:midTestPlayer)
    :ok = Player.join_game(player1, :testGame)
    Player.deal_card(player1, %Beans.GreenBean{})
    Player.start_game(player1)

    Player.start_turn(player1)
    Player.skip_mid_cards(player1)
    assert_state :play_cards, for: player1
    :ok = Player.play_card(player1, 1)
    assert_state :bonus_cards, for: player1

    set_mid_cards(:testGame, [%Beans.GreenBean{}, %Beans.SoyBean{}, %Beans.GreenBean{}])
    :ok = Player.play_mid_card(player1, 0, 1)
    IO.puts inspect :ets.lookup(:testGameTable, :testGame)
    :ok = Player.play_mid_card(player1, 1, 1)
    :ok = Player.play_mid_card(player1, 0, 2)
    Player.end_turn(player1)
    assert_state :no_turn, for: player1

    Player.stop(player1)
  end

  test "Pick some mid cards" do
    {:ok, player1} = Player.start_link(:midTestPlayer2)
    :ok = Player.join_game(player1, :testGame)
    Player.deal_card(player1, %Beans.GreenBean{})
    Player.start_game(player1)
    Player.start_turn(player1)
    Player.skip_mid_cards(player1)
    assert_state :play_cards, for: player1
    :ok = Player.play_card(player1, 1)
    assert_state :bonus_cards, for: player1

    set_mid_cards(:testGame, [%Beans.GreenBean{}, %Beans.SoyBean{}, %Beans.GreenBean{}])
    :ok = Player.play_mid_card(player1, 0, 1)
    :ok = Player.pass(player1)
    Player.end_turn(player1)
    assert_state :no_turn, for: player1

    Player.stop(player1)
  end

  test "Take illegal card" do
    {:ok, player1} = Player.start_link(:midTestPlayer3)
    :ok = Player.join_game(player1, :testGame)
    Player.deal_card(player1, %Beans.GreenBean{})
    Player.start_game(player1)
    Player.start_turn(player1)
    Player.skip_mid_cards(player1)
    assert_state :play_cards, for: player1
    :ok = Player.play_card(player1, 1)
    assert_state :bonus_cards, for: player1

    set_mid_cards(:testGame, [%Beans.GreenBean{}, %Beans.SoyBean{}, %Beans.GreenBean{}])
    {:error, :illegal_move} = Player.play_mid_card(player1, 1, 1)
    :ok = Player.pass(player1)
    Player.end_turn(player1)
    assert_state :no_turn, for: player1

    Player.stop(player1)
  end

  test "Initial cards" do
    {:ok, player1} = Player.start_link(:initTestPlayer)
    :ok = Player.join_game(player1, :testGame)
    Player.deal_card(player1, %Beans.GreenBean{})
    Player.start_game(player1)
    Player.start_turn(player1)
    assert_state :initial_cards, for: player1
    set_mid_cards(:testGame, [%Beans.GreenBean{}, %Beans.SoyBean{}])
    :ok = Player.play_mid_card(player1, 0, 1)
    :ok = Player.play_mid_card(player1, 0, 2)
    Player.skip_mid_cards(player1)
    assert_state :play_cards, for: player1

    Player.stop(player1)
  end

  test "Discard an initial card" do
    {:ok, player1} = Player.start_link(:initTestPlayer2)
    :ok = Player.join_game(player1, :testGame)
    Player.deal_card(player1, %Beans.GreenBean{})
    Player.start_game(player1)
    Player.start_turn(player1)
    assert_state :initial_cards, for: player1
    set_mid_cards(:testGame, [%Beans.GreenBean{}, %Beans.SoyBean{}])
    :ok = Player.play_mid_card(player1, 0, 1)
    {:error, :illegal_move} = Player.play_mid_card(player1, 0, 1)
    :ok = Player.discard_mid_card(player1, 0)
    Player.skip_mid_cards(player1)
    assert_state :play_cards, for: player1

    Player.stop(player1)
  end

  test "Skip initial cards" do
    {:ok, player1} = Player.start_link(:initTestPlayer3)
    :ok = Player.join_game(player1, :testGame)
    Player.deal_card(player1, %Beans.GreenBean{})
    Player.start_game(player1)
    Player.start_turn(player1)
    assert_state :initial_cards, for: player1
    set_mid_cards(:testGame, [%Beans.GreenBean{}, %Beans.SoyBean{}])
    :ok = Player.pass(player1)
    assert_state :play_cards, for: player1

    Player.stop(player1)
  end

  test "Scoring" do
    {:ok, player1} = Player.start_link(:scorePlayer)
    :ok = Player.join_game(player1, :testGame)
    Player.deal_card(player1, %Beans.GreenBean{})
    Player.deal_card(player1, %Beans.WaxBean{})
    Player.start_game(player1)
    Player.start_turn(player1)
    assert_state :initial_cards, for: player1
    set_mid_cards(:testGame, [%Beans.GreenBean{}, %Beans.GreenBean{}, %Beans.GreenBean{}])
    :ok = Player.play_mid_card(player1, 0, 1)
    :ok = Player.play_mid_card(player1, 0, 1)
    :ok = Player.play_mid_card(player1, 0, 1)
    Player.skip_mid_cards(player1)
    Player.play_card(player1, 1)
    Player.harvest(player1, 1)
    Player.play_card(player1, 1)
    :ok = Player.pass(player1)
    1 = Player.end_game(player1)
  end

  test "Third field" do
    {:ok, player1} = Player.start_link(:thirdFieldPlayer)
    :ok = Player.join_game(player1, :testGame)
    Player.deal_card(player1, %Beans.RedBean{})
    Player.deal_card(player1, %Beans.WaxBean{})
    Player.start_game(player1)
    Player.start_turn(player1)
    {:error, :illegal_move} = Player.purchase_third_field(player1)

    set_mid_cards(:testGame, [%Beans.RedBean{}, %Beans.RedBean{}, %Beans.RedBean{}])
    :ok = Player.play_mid_card(player1, 0, 1)
    :ok = Player.play_mid_card(player1, 0, 1)
    :ok = Player.play_mid_card(player1, 0, 1)
    Player.skip_mid_cards(player1)
    Player.play_card(player1, 1)
    Player.harvest(player1, 1)
    :ok = Player.purchase_third_field(player1)
    :ok = Player.play_card(player1, 3)

    Player.stop(player1)
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

