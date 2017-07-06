defmodule Player do
  @moduledoc false
  use GenStateMachine, callback_mode: [:state_functions, :state_enter]

  defmodule State do
    defstruct name: nil, game: nil, hand: Hand.new(), field: BeanField.new(), score: 0, cards_played: 0
  end

## API
  def start_link(name) do
    GenStateMachine.start_link( __MODULE__, [name], name: name)
  end

  def stop(name) do
    GenStateMachine.stop(name)
  end
# Upstream API
  def join_game(name, gameName) do
    GenStateMachine.call(name, {:join_game, gameName})
  end

  def see_hand(name) do
    GenStateMachine.call(name, :get_hand)
  end

  def see_fields(name) do
    GenStateMachine.call(name, :see_fields)
  end

  def play_card(name, field) do
    GenStateMachine.call(name, {:play_card, field})
  end

  def discard_card(name, n) do
    GenStateMachine.cast(name, {:discard, n})
  end

  def harvest(name, field) do
    GenStateMachine.call(name, {:harvest, field})
  end

  def play_mid_card(name, card, fieldIndex) do
    GenStateMachine.call(name, {:take_mid_card, card, fieldIndex})
  end

  def discard_mid_card(name, card) do
    GenStateMachine.cast(name, {:discard_mid_card, card})
  end

  def purchase_third_field(name) do
    GenStateMachine.call(name, :purchase_third_field)
  end

  def pass(name) do
    GenStateMachine.call(name, :pass)
  end
# Downstream API
  def deal_card(name, card) do
    GenStateMachine.cast(name, {:deal_card, card})
  end

  def start_turn(name) do
    GenStateMachine.cast(name, :start_turn)
  end

##  GenServer callbacks
  def init([name]) do
    {:ok, :waiting_to_start, %Player.State{name: name}}
  end

  def waiting_to_start(:enter, _, _) do
    :keep_state_and_data
  end
  def waiting_to_start({:call, from}, {:join_game, gameName}, %Player.State{name: name} = state) do
    :ok = BeanGame.register_player(gameName, name)
    GenStateMachine.reply(from, :ok)
    {:next_state, :no_turn, %Player.State{state | game: gameName}}
  end

  def no_turn(:enter, _, _) do
    :keep_state_and_data
  end
  def no_turn(:cast, :start_turn, %Player.State{name: name, game: gameName} = state) do
    IO.puts("[#{name}] Turn start!")
    case BeanGame.get_mid_cards(gameName) do
      [] -> {:next_state, :play_cards, state}
      _ -> {:next_state, :offered_bonus_cards, state}
    end
  end
  def no_turn(eventType, event, state) do
    handle_event(eventType, event, state)
  end

  def play_cards(:enter, _, state) do
    {:keep_state, %Player.State{ state | cards_played: 0}}
  end
  def play_cards({:call, from}, {:play_card, fieldIndex}, %Player.State{field: field, hand: hand, cards_played: n} = state) do
    {cardToPlay, rest} = Hand.play_card(hand)
    case BeanField.plant_bean(field, fieldIndex, cardToPlay) do
      {:error, :not_allowed} ->
        GenStateMachine.reply(from, {:error, :illegal_move})
        :keep_state_and_data
      newField when n <= 1->
        GenStateMachine.reply(from, :ok)
        {:keep_state, %Player.State{state | field: newField, hand: rest, cards_played: n + 1}}
      newField ->
        GenStateMachine.reply(from, :ok)
        {:next_state, :discard, %Player.State{state | field: newField, hand: rest, cards_played: 0}}
    end
  end
  def play_cards({:call, from}, :pass, %Player.State{cards_played: 0} = state) do
    GenStateMachine.reply(from, {:error, :illegal_move})
    :keep_state_and_data
  end
  def play_cards({:call, from}, :pass, state) do
    GenStateMachine.reply(from, :ok)
    {:next_state, :discard, state}
  end
  def play_cards(eventType, event, state) do
    handle_event(eventType, event, state)
  end

  def discard(:enter, _, %Player.State{hand: []} = state) do
    {:next_state, :bonus_cards, state}
  end
  def discard(:enter, _, _) do
    :keep_state_and_data
  end
  def discard(:cast, {:discard, n}, %Player.State{hand: hand, game: gameName} = state) do
    {discarded, newHand} = Hand.discard_card(hand, n + 1)
    BeanGame.discard_cards(gameName, [discarded])
    {:next_state, :bonus_cards, %Player.State{ state | hand: newHand}}
  end
  def discard({:call, from}, :pass, state) do
    GenStateMachine.reply(from, :ok)
    {:next_state, :bonus_cards, state}
  end
  def discard(eventType, event, state) do
    handle_event(eventType, event, state)
  end

  def bonus_cards(:enter, _, %Player.State{game: gameName} = state) do
    BeanGame.new_bonus_cards(gameName)
    :keep_state_and_data
  end

  def handle_event(:cast, {:deal_card, card}, %Player.State{hand: hand} = state) do
    {:keep_state, %Player.State{state | hand: Hand.add_card(card, hand)}}
  end
  def handle_event({:call, from}, {:harvest, fieldIndex}, %Player.State{field: field, score: score, game: gameName} = state) do
    case BeanField.harvest_field(field, fieldIndex) do
      {:error, :not_allowed} ->
        GenStateMachine.reply(from, {:error, :illegal_move})
        {:keep_state, state,}
      {newField, {harvestPoints, discard}} ->
        BeanGame.discard_cards(gameName, discard)
        GenStateMachine.reply(from, :ok)
        {:keep_state, %{state | field: newField, score: score + length(harvestPoints)}}
    end
  end
  def handle_event({:call, from}, :get_hand, %Player.State{hand: hand} = state) do
    {:keep_state, state, [{:reply, from, hand}]}
  end
  def handle_event({:call, from}, :see_fields, %Player.State{field: field} = state) do
    {:keep_state, state, [{:reply, from, field}]}
  end
  def handle_event({:call, from}, :purchase_third_field, %Player.State{field: %{3 => :not_available} = field, score: score} = state) when score >= 3 do
    {:keep_state, %{state| field: BeanField.buy_field(field), score: score - 3}, [{:reply, from, :ok}]}
  end
  def handle_event({:call, from}, :purchase_third_field, state) do
    {:keep_state, state, [{:reply, from, {:error, :illegal_move}}]}
  end
  def handle_event({:call, from}, _, state) do
    {:keep_state, state, [{:reply, from, {:error, :illegal_move}}]}
  end


end