defmodule GameTest do
  use ExUnit.Case
  alias ExBeans.Deck
  alias ExBeans.Player  
  alias ExBeans.Beans
  alias ExBeans.BeanGame
  @moduledoc false

  setup_all do
    :ets.new(:gameTestTab, [:named_table, :set, :public])
    :meck.new(Player)
    :meck.expect(Player, :deal_card, 2, :ok)
    :meck.expect(Player, :start_turn, 1, fn(_) -> send(:testProc, :start_turn) end)
    :meck.expect(Player, :start_game, 1, fn(_) -> send(:testProc, :start_game) end)
    :meck.expect(Player, :skip_mid_cards, 1, fn(_) -> send(:testProc, :skip_mid_cards) end)
    :meck.expect(Player, :end_turn, 1, fn(_) -> send(:testProc, :end_turn) end)
    :meck.expect(Player, :end_game, 1, fn(_) -> send(:testProc, :end_game) end)
    :meck.new(Deck, [:passthrough])
    :meck.expect(Deck, :draw,   fn (_) ->
                                  case :ets.lookup(:gameTestTab, :testKey) do
                                    [{:testKey, []}] -> :empty
                                    [{:testKey, [card | rest]}] ->
                                      :ets.insert(:gameTestTab, {:testKey, rest})
                                      {card, rest}
                                  end
                                end)
  end
#    @callback register_player(BeanGameName, Player.playerName) :: :ok
#    @callback discard_cards(BeanGameName, [Beans.bean]) :: :ok
#    @callback get_mid_cards(BeanGameName) :: [Beans.bean]
#    @callback new_mid_cards(BeanGameName) :: :ok
#    @callback get_mid_card(BeanGameName, integer) :: {:ok, Beans.bean} | {:error, :invalid_card}
#    @callback remove_mid_card(BeanGameName, integer) :: :ok | {:error, :invalid_card}
#    @callback player_done(BeanGameName) :: :ok

  test "GameBoard" do
    {:ok, pid} = BeanGame.start_link(:testGame)
    assert Process.alive?(pid)
  end

  test "Register players and start" do
    Process.register(self(), :testProc)
    initial_cards()

    {:ok, pid} = BeanGame.start_link(:testGame)
    :ok = BeanGame.register_player(pid, self(), :testProc)
    :ok = BeanGame.register_player(pid, self(), :testProc)
    assert_receive :start_turn
    assert_receive :start_game
    assert_receive :skip_mid_cards
  end

  test "Get new mid cards and play them" do
    Process.register(self(), :testProc)
    initial_cards()

    {:ok, pid} = BeanGame.start_link(:testGame)
    :ok = BeanGame.register_player(pid, self(), :testProc)
    :ok = BeanGame.register_player(pid, self(), :testProc)
    set_deck([%Beans.CoffeeBean{}, %Beans.WaxBean{}, %Beans.SoyBean{}])

    BeanGame.new_mid_cards(pid)
    [%Beans.CoffeeBean{}, %Beans.WaxBean{}, %Beans.SoyBean{}] = BeanGame.get_mid_cards(pid)

    {:ok, %Beans.SoyBean{}} = BeanGame.get_mid_card(pid, 2)
    :ok = BeanGame.remove_mid_card(pid, 2)
    {:error, :invalid_card}= BeanGame.get_mid_card(pid, 2)
  end

  test "Discard in mid cards" do
    Process.register(self(), :testProc)
    initial_cards()

    {:ok, pid} = BeanGame.start_link(:testGame)
    :ok = BeanGame.register_player(pid, self(), :testProc)
    :ok = BeanGame.register_player(pid, self(), :testProc)
    set_deck([%Beans.CoffeeBean{}, %Beans.WaxBean{}, %Beans.SoyBean{}])

    BeanGame.set_callback(pid, fn(event, data) -> send(:testProc, {event, data}) end)

    BeanGame.discard_cards(pid, [%Beans.WaxBean{}])
    BeanGame.new_mid_cards(pid)
    [%Beans.WaxBean{}, %Beans.CoffeeBean{}, %Beans.WaxBean{}, %Beans.SoyBean{}] = BeanGame.get_mid_cards(pid)

    assert_receive {:new_discards, []} 
    assert_receive {:new_mid_cards, [%Beans.WaxBean{}, %Beans.CoffeeBean{}, %Beans.WaxBean{}, %Beans.SoyBean{}]}

    {:ok, %Beans.SoyBean{}} = BeanGame.get_mid_card(pid, 3)
    :ok = BeanGame.remove_mid_card(pid, 3)
    {:ok, %Beans.WaxBean{}} = BeanGame.get_mid_card(pid, 2)
  end

  test "Player turn end and initial cards" do
    Process.register(self(), :testProc)
    initial_cards()

    {:ok, pid} = BeanGame.start_link(:testGame)
    :ok = BeanGame.register_player(pid, self(), :testProc)
    :ok = BeanGame.register_player(pid, self(), :testProc)
    assert_receive :start_turn
    assert_receive :skip_mid_cards
    set_deck([%Beans.CoffeeBean{}, %Beans.WaxBean{}, %Beans.SoyBean{}, %Beans.RedBean{}, %Beans.RedBean{}, %Beans.RedBean{}])

    BeanGame.new_mid_cards(pid)
    BeanGame.player_done(pid)
    assert_receive :end_turn
    assert_receive :start_turn
    refute_receive :skip_mid_cards
  end

  test "No initial for player two" do
    Process.register(self(), :testProc)
    initial_cards()

    {:ok, pid} = BeanGame.start_link(:testGame)
    :ok = BeanGame.register_player(pid, self(), :testProc)
    :ok = BeanGame.register_player(pid, self(), :testProc)
    assert_receive :start_turn
    assert_receive :skip_mid_cards
    set_deck([%Beans.CoffeeBean{}, %Beans.WaxBean{}, %Beans.SoyBean{}, %Beans.RedBean{}, %Beans.RedBean{}, %Beans.RedBean{}])

    BeanGame.new_mid_cards(pid)
    :ok = BeanGame.remove_mid_card(pid, 0)
    :ok = BeanGame.remove_mid_card(pid, 0)
    :ok = BeanGame.remove_mid_card(pid, 0)
    BeanGame.player_done(pid)
    assert_receive :end_turn
    assert_receive :start_turn
    assert_receive :skip_mid_cards
  end

  test "Game ends, no more cards" do
    Process.register(self(), :testProc)
    initial_cards()

    {:ok, pid} = BeanGame.start_link(:testGame)
    :ok = BeanGame.register_player(pid, self(), :testProc)
    :ok = BeanGame.register_player(pid, self(), :testProc)
    assert_receive :start_turn
    assert_receive :skip_mid_cards
    set_deck([%Beans.CoffeeBean{}, %Beans.WaxBean{}])

    BeanGame.new_mid_cards(pid)
    BeanGame.player_done(pid)
    assert_receive :end_game
    assert_receive :end_game
  end



  defp set_deck(cards) do
    :ets.insert(:gameTestTab, {:testKey, cards})
  end

  defp initial_cards() do
    set_deck(List.duplicate(%Beans.GreenBean{}, 10))
  end



end
