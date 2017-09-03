defmodule ExBeans.Player do
  @moduledoc """
  This module implements the player functionality in a game of Bohnanza.

  The player process keeps track of all the information a player owns, that is their hand and bean fields. It also
  keeps track of the current player turn phase.
  """
  require Logger
  use GenStateMachine, callback_mode: [:state_functions, :state_enter]
  alias ExBeans.Hand
  alias ExBeans.BeanField
  alias ExBeans.Player
  alias ExBeans.BeanGame
#  @game_api Application.fetch_env!(:exbeans, :game_api)

  @typedoc "The player's reference."
  @type player_name   :: atom() | pid()
  @typedoc "Player state name"
  @type state_name    :: :no_turn | :initial_cards | :play_cards | :discard | :bonus_cards | :end_turn
  @typedoc "Callback for communicating with the layer above"
  @type player_callback :: ((state_name(), Hand.hand, BeanField.beanField) -> :ok)

  defmodule State do
    @moduledoc false
    defstruct name: nil, game: nil, hand: Hand.new(), field: BeanField.new(), score: 0, cards_played: 0, player_callback: nil
  end

## -------------------------------------- API --------------------------------------
  @doc "Start the player server."
  @spec start_link(player_name) :: {:ok, pid}
  def start_link(name) do
    GenStateMachine.start_link( __MODULE__, [name])
  end

  @doc "Stop the player server."
  @spec stop(player_name) :: :ok
  def stop(name) do
    GenStateMachine.stop(name)
  end

## -------------------------------- Upstream API -----------------------------------
  @doc "Join a new game of Bohnanza with the player."
  @spec join_game(player_name, Game.game_name, player_callback) :: :ok
  def join_game(name, gameName, player_callback \\ fn(_,_,_) -> :ok end) do
    GenStateMachine.call(name, {:join_game, gameName, player_callback})
  end

  @doc "Peek at the players hand."
  @spec see_hand(player_name) :: Hand.hand
  def see_hand(name) do
    GenStateMachine.call(name, :get_hand)
  end

  @doc "Peek at the players bean fields."
  @spec see_fields(player_name) :: BeanField.beanField
  def see_fields(name) do
    GenStateMachine.call(name, :see_fields)
  end

  @doc """
  Play the first card on the player's hand. A player can play cards after he has gone through the mid-field cards
  left by the other player. He must play at least one card a turn and can play up to two.
  """
  @spec play_card(player_name, BeanField.beanFieldIndex) :: :ok | {:error, :illegal_move}
  def play_card(name, field) do
    GenStateMachine.call(name, {:play_card, field})
  end

  @doc """
  Discard the nth (1-based) card from the hand. Can only be done after the player played their cards and only once
  per turn.
  """
  @spec discard_card(player_name, pos_integer) :: :ok | {:error, :illegal_move}
  def discard_card(name, n) do
    GenStateMachine.call(name, {:discard, n})
  end

  @doc "Harvest a specified bean field. This can be done only in player's turn. "
  @spec harvest(player_name, BeanField.beanFieldIndex) :: :ok | {:error, :illegal_move}
  def harvest(name, field) do
    GenStateMachine.call(name, {:harvest, field})
  end

  @doc "Play a card from the mid-field. Can only be done at the beginning or end of the turn."
  @spec play_mid_card(player_name, non_neg_integer, BeanField.beanFieldIndex) :: :ok | {:error, :illegal_move}
  def play_mid_card(name, cardIndex, fieldIndex) do
    GenStateMachine.call(name, {:play_mid_card, cardIndex, fieldIndex})
  end

  @doc "Discard a card from the mid-field. Can only be done at the beginning of the turn."
  @spec discard_mid_card(player_name, non_neg_integer) :: :ok | {:error, :illegal_move}
  def discard_mid_card(name, cardIndex) do
    GenStateMachine.call(name, {:discard_mid_card, cardIndex})
  end

  @doc "Purchase the third field for 3 points."
  @spec purchase_third_field(player_name) :: :ok | {:error, :illegal_move}
  def purchase_third_field(name) do
    GenStateMachine.call(name, :purchase_third_field)
  end

  @doc "Pass either on using the initial cards, playing the second card or using the mid-field cards at the end."
  @spec pass(player_name) :: :ok | {:error, :illegal_move}
  def pass(name) do
    GenStateMachine.call(name, :pass)
  end

## ------------------------------- Downstream API ----------------------------------
  @doc "Deal a card to the player."
  @spec deal_card(player_name, Beans.bean) :: :ok
  def deal_card(name, card) do
    GenStateMachine.cast(name, {:deal_card, card})
  end
  
  @doc "Notify the player that the game has started."
  @spec start_game(player_name) :: :ok
  def start_game(name) do
    GenStateMachine.cast(name, :start_game)
  end

  @doc "Notify the player that their turns has started."
  @spec start_turn(player_name) :: :ok
  def start_turn(name) do
    GenStateMachine.cast(name, :start_turn)
  end

  @doc "Notify the player that their turns has ended."
  @spec end_turn(player_name) :: :ok
  def end_turn(name) do
    GenStateMachine.cast(name, :end_turn)
  end

  @doc "Notify the player that their turns has ended."
  @spec skip_mid_cards(player_name) :: :ok
  def skip_mid_cards(name) do
    GenStateMachine.cast(name, :skip_mid_cards)
  end

  @doc "Notify the player that the whole game has ended."
  @spec end_game(player_name) :: non_neg_integer
  def end_game(name) do
    GenStateMachine.call(name, :end_game)
  end

##  GenServer callbacks

  @doc false
  def init([name]) do
    {:ok, :waiting_to_start, %Player.State{name: name}}
  end

  @doc false
  def waiting_to_start(:enter, _, _) do
    :keep_state_and_data
  end
  def waiting_to_start({:call, from}, {:join_game, gameName, player_callback}, %Player.State{name: name} = state) do
    :ok = BeanGame.register_player(gameName, self(), name)
    GenStateMachine.reply(from, :ok)
    {:keep_state, %Player.State{state | game: gameName, player_callback: player_callback}}
  end
  def waiting_to_start(:cast, :start_game, state) do
    {:next_state, :no_turn ,state}
  end
  def waiting_to_start(eventType, event, state) do
    handle_event(eventType, event, state)
  end

  @doc false
  def no_turn(:enter, _, state) do
     pushState(:no_turn, state)
    :keep_state_and_data
  end
  def no_turn(:cast, :start_turn, %Player.State{name: name} = state) do
    Logger.debug("[#{name}] Turn start!")
    {:next_state, :initial_cards, state}
  end
  def no_turn({:call, from}, {:harvest, _fieldIndex}, state) do
    {:keep_state, state, [{:reply, from, {:error, :illegal_move}}]}
  end
  def no_turn({:call, from}, :end_game, %Player.State{score: score} = state) do
    GenStateMachine.reply(from, score)
    {:stop, :normal, state}
  end
  def no_turn(eventType, event, state) do
    handle_event(eventType, event, state)
  end


  @doc false
  def initial_cards(:enter, _, state) do
     pushState(:initial_cards, state)
    :keep_state_and_data
  end
  def initial_cards(:cast, :skip_mid_cards, %Player.State{hand: []} = state) do
    {:next_state, :bonus_cards, state}
  end
  def initial_cards(:cast, :skip_mid_cards, state) do
    {:next_state, :play_cards, state}
  end
  def initial_cards({:call, from}, {:play_mid_card, cardIndex, fieldIndex}, %Player.State{field: field, game: gameName} = state) do
    with {:ok, card}       <- BeanGame.get_mid_card(gameName, cardIndex),
         %{} = newField    <- BeanField.plant_bean(field, fieldIndex, card),
         :ok               <- BeanGame.remove_mid_card(gameName, cardIndex)
    do
      GenStateMachine.reply(from, :ok)
      {:keep_state, %Player.State{ state | field: newField}}
    else
      {:error, :not_allowed} ->
        GenStateMachine.reply(from, {:error, :illegal_move})
        :keep_state_and_data
      {:error, :invalid_card} ->
        GenStateMachine.reply(from, {:error, :illegal_move})
        :keep_state_and_data
    end
  end
  def initial_cards({:call, from}, {:discard_mid_card, cardIndex}, %Player.State{game: gameName} = state) do
    with {:ok, card}       <- BeanGame.get_mid_card(gameName, cardIndex),
         :ok               <- BeanGame.remove_mid_card(gameName, cardIndex)
    do
      BeanGame.discard_cards(gameName, [card])
      GenStateMachine.reply(from, :ok)
      {:keep_state, state}
    else
      {:error, :invalid_card} ->
        GenStateMachine.reply(from, {:error, :illegal_move})
        :keep_state_and_data
    end
  end
  def initial_cards({:call, from}, :pass, state) do
    GenStateMachine.reply(from, :ok)
    {:next_state, :play_cards, state}
  end
  def initial_cards(eventType, event, state) do
    handle_event(eventType, event, state)
  end

  @doc false
  def play_cards(:enter, _, state) do
     pushState(:play_cards, state)
    {:keep_state, %Player.State{ state | cards_played: 0}}
  end
  def play_cards({:call, from}, {:play_card, fieldIndex}, %Player.State{field: field, hand: hand, cards_played: n} = state) do
    {cardToPlay, rest} = Hand.play_card(hand)
    case BeanField.plant_bean(field, fieldIndex, cardToPlay) do
      {:error, :not_allowed} ->
        GenStateMachine.reply(from, {:error, :illegal_move})
        :keep_state_and_data
      newField when n < 1 and rest == [] ->
        GenStateMachine.reply(from, :ok)
        {:next_state, :bonus_cards, %Player.State{state | field: newField, hand: rest, cards_played: n + 1}}
      newField when n < 1->
        GenStateMachine.reply(from, :ok)
        {:keep_state, %Player.State{state | field: newField, hand: rest, cards_played: n + 1}}
      newField when rest == [] ->
        GenStateMachine.reply(from, :ok)
        {:next_state, :bonus_cards, %Player.State{state | field: newField, hand: rest}}
      newField ->
        GenStateMachine.reply(from, :ok)
        {:next_state, :discard, %Player.State{state | field: newField, hand: rest}}
    end
  end
  def play_cards({:call, from}, :pass, %Player.State{cards_played: 0}) do
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

  @doc false
  def discard(:enter, _, state) do
     pushState(:discard, state)
    :keep_state_and_data
  end
  def discard({:call, from}, {:discard, n}, %Player.State{hand: hand, game: gameName} = state) do
    {discarded, newHand} = Hand.discard_card(hand, n - 1)
    BeanGame.discard_cards(gameName, [discarded])
    GenStateMachine.reply(from, :ok)
    {:next_state, :bonus_cards, %Player.State{ state | hand: newHand}}
  end
  def discard({:call, from}, :pass, state) do
    GenStateMachine.reply(from, :ok)
    {:next_state, :bonus_cards, state}
  end
  def discard(eventType, event, state) do
    handle_event(eventType, event, state)
  end

  @doc false
  def bonus_cards(:enter, _, state = %Player.State{game: gameName}) do
    pushState(:bonus_cards, state)
    BeanGame.new_mid_cards(gameName)
    :keep_state_and_data
  end
  def bonus_cards({:call, from}, {:play_mid_card, cardIndex, fieldIndex}, %Player.State{field: field, game: gameName} = state) do
    with {:ok, card}       <- BeanGame.get_mid_card(gameName, cardIndex),
         %{} = newField    <- BeanField.plant_bean(field, fieldIndex, card),
         :ok               <- BeanGame.remove_mid_card(gameName, cardIndex)
    do
      GenStateMachine.reply(from, :ok)
      {:keep_state, %Player.State{ state | field: newField}}
    else
      {:error, :not_allowed} ->
        GenStateMachine.reply(from, {:error, :illegal_move})
        :keep_state_and_data
      {:error, :invalid_card} ->
        GenStateMachine.reply(from, {:error, :illegal_move})
        :keep_state_and_data
    end
  end
  def bonus_cards({:call, from}, :pass, %Player.State{game: gameName} = state) do
    BeanGame.player_done(gameName)
    GenStateMachine.reply(from, :ok)
    {:next_state, :end_turn, state}
  end
  def bonus_cards(:cast, :end_turn, %Player.State{name: player} = state) do
    Logger.debug("[#{player}] Turn ended.")
    {:next_state, :no_turn, state}
  end
  def bonus_cards({:call, from}, :end_game, %Player.State{score: score} = state) do
    GenStateMachine.reply(from, score)
    {:stop, :normal, state}
  end
  def bonus_cards(eventType, event, state) do
    handle_event(eventType, event, state)
  end

  def end_turn(:enter, _, state = %Player.State{game: gameName}) do
    pushState(:end_turn, state)
    BeanGame.new_mid_cards(gameName)
    :keep_state_and_data
  end
  def end_turn(:cast, :end_turn, %Player.State{name: player} = state) do
    Logger.debug("[#{player}] Turn ended.")
    {:next_state, :no_turn, state}
  end
  def end_turn({:call, from}, :end_game, %Player.State{score: score} = state) do
    GenStateMachine.reply(from, score)
    {:stop, :normal, state}
  end

  @doc false
  defp handle_event(:cast, {:deal_card, card}, %Player.State{hand: hand} = state) do
    {:keep_state, %Player.State{state | hand: Hand.add_card(card, hand)}}
  end
  defp handle_event({:call, from}, {:harvest, fieldIndex}, %Player.State{field: field, score: score, game: gameName} = state) do
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
  defp handle_event({:call, from}, :get_hand, %Player.State{hand: hand} = state) do
    {:keep_state, state, [{:reply, from, hand}]}
  end
  defp handle_event({:call, from}, :see_fields, %Player.State{field: field} = state) do
    {:keep_state, state, [{:reply, from, field}]}
  end
  defp handle_event({:call, from}, :purchase_third_field, %Player.State{field: %{3 => :not_available} = field, score: score} = state) when score >= 3 do
    {:keep_state, %{state| field: BeanField.buy_field(field), score: score - 3}, [{:reply, from, :ok}]}
  end
  defp handle_event({:call, from}, :purchase_third_field, state) do
    {:keep_state, state, [{:reply, from, {:error, :illegal_move}}]}
  end
  defp handle_event({:call, from}, _, state) do
    {:keep_state, state, [{:reply, from, {:error, :illegal_move}}]}
  end

  defp pushState(state_name, %Player.State{hand: hand, field: field, player_callback: player_callback}) do
    player_callback.(state_name, hand, field)
  end
end
