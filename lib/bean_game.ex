defmodule ExBeans.BeanGame do
  @moduledoc false
  @type game_name :: atom | pid
  @type game_event :: :new_mid_cards | :new_discards
  @type game_callback :: ((game_event, list(ExBeans.Beans.bean())) -> :ok)
  
  require Logger
  alias ExBeans.Player
  alias ExBeans.Deck
  use GenServer

    defmodule State do
      defstruct name: nil, deck: Deck.new(), discard: [], players: nil, extra_cards: [], game_over: false, callback: nil
    end


## API
  def start_link(gameName, callback \\ fn(_,_) -> :ok end) do
    GenServer.start_link(__MODULE__, [gameName, callback])
  end

  def register_player(gameName, player, playerName) do
    GenServer.call(gameName, {:register, player, playerName})
  end

  def discard_cards(gameName, cards) do
    GenServer.cast(gameName, {:discard, cards})
  end

  def get_mid_cards(gameName) do
    GenServer.call(gameName, :get_mid_cards)
  end

  def new_mid_cards(gameName) do
    GenServer.cast(gameName, :new_bonus_cards)
  end

  def get_mid_card(gameName, index) do
    GenServer.call(gameName, {:get_mid_card, index})
  end

  def remove_mid_card(gameName, index) do
    GenServer.call(gameName, {:remove_mid_card, index})
  end

  def player_done(gameName) do
    GenServer.cast(gameName, :player_done)
  end

  def set_callback(gameName, callback) do
    GenServer.cast(gameName, {:callback, callback})
  end

##  GenServer callbacks

  def init([gameName, callback]) do
    Logger.debug "New game of Bohnanza started #{gameName}!"
    Logger.debug "[#{gameName}] Waiting for players"

    {:ok, %State{name: gameName, callback: callback}}
  end

  def handle_call({:register, player, playerName}, _from, %State{name: gameName, players: nil} = state) do
    Logger.debug "[#{gameName}] Registered player: #{playerName}"
    {:reply, :ok, %State{state | players: [player]}}
  end
  def handle_call({:register, player2, player2Name}, _from, %State{name: gameName, players: [player1], deck: deck} = state) do
    Logger.debug "[#{gameName}] Registered player: #{player2Name}"
    playerOrder = Enum.shuffle([player1, player2])
    deckAfterDealing = deal_cards(length(playerOrder) * 5, playerOrder, deck)
    # Logger.debug "[#{gameName}] Starting game: #{player1} vs. #{player2}. #{hd(playerOrder)} will start!"
    for player <- playerOrder do Player.start_game(player) end
    Player.start_turn(hd(playerOrder))
    Player.skip_mid_cards(hd(playerOrder))
    {:reply, :ok, %State{state | players: playerOrder, deck: deckAfterDealing}}
  end
  def handle_call(:get_mid_cards, _from, %State{extra_cards: bonus} = state) do
    {:reply, bonus, state}
  end
  def handle_call({:get_mid_card, index}, _from, %State{extra_cards: bonus} = state) do
    case Enum.at(bonus, index) do
      nil -> {:reply, {:error, :invalid_card}, state}
      card -> {:reply, {:ok, card}, state}
    end
  end
  def handle_call({:remove_mid_card, index}, _from, %State{extra_cards: bonus} = state) do
    case Enum.at(bonus, index) do
      nil -> {:reply, {:error, :invalid_card}, state}
      _card -> {:reply, :ok, %State{ state | extra_cards: List.delete_at(bonus, index)}}
    end
  end

  def handle_cast({:discard, cards}, %State{discard: disc, callback: callback} = state) do
    callback.(:new_discards, cards)
    {:noreply, %State{state | discard: cards ++ disc}}
  end
  def handle_cast(:new_bonus_cards, %State{deck: deck, discard: discard, callback: callback} = state) do
     case draw_cards(3, deck, []) do
       {[], newMid} ->
         {midWithDiscard, newDiscard} = fill_discard(newMid, discard)
         report(callback, midWithDiscard, newDiscard)
         {:noreply, %State{state | extra_cards: midWithDiscard, discard: newDiscard, game_over: true}}
       {newDeck, newMid} ->
         {midWithDiscard, newDiscard} = fill_discard(newMid, discard)
         report(callback, midWithDiscard, newDiscard)
         {:noreply, %State{state | extra_cards: midWithDiscard, discard: newDiscard, deck: newDeck}}
     end
  end
  def handle_cast(:player_done, %State{name: gameName, game_over: true, players: [currentPlayer, nextPlayer]} = state) do
    end_the_game(gameName, currentPlayer, nextPlayer)
    {:stop, :normal, state}
  end
  def handle_cast(:player_done, %State{name: gameName, extra_cards: bonus_cards, players: [currentPlayer, nextPlayer], deck: deck} = state) do
    case draw_cards(2, deck, []) do
      {[], _} ->
        end_the_game(gameName, currentPlayer, nextPlayer)
        {:stop, :normal, state}
      {newDeck, cards} ->
        for card <- cards do Player.deal_card(currentPlayer, card) end
        Player.end_turn(currentPlayer)
        Player.start_turn(nextPlayer)
        if bonus_cards == [] do Player.skip_mid_cards(nextPlayer) end
        {:noreply, %State{state| deck: newDeck, players: [nextPlayer, currentPlayer]}}
    end
  end
  def handle_cast( {:callback, callback}, state) do
    {:noreply, %State{state| callback: callback}}
  end

  defp draw_cards(n, deck, acc) when n > 0 do
    case Deck.draw(deck) do
      :empty -> {deck, acc}
      {card, newDeck} -> draw_cards(n-1, newDeck, acc ++ [card])
    end
  end
  defp draw_cards(0, deck, acc) do
    {deck, acc}
  end

  defp fill_discard(bonusCards, []) do
    {bonusCards, []}
  end
  defp fill_discard(bonusCards, [firstDiscard | restDiscard]) do
    case Enum.member?(bonusCards, firstDiscard) do
      true -> fill_discard([firstDiscard | bonusCards], restDiscard)
      false -> {bonusCards, [firstDiscard | restDiscard]}
    end
  end

  defp deal_cards(0, _, deck) do
    deck
  end
  defp deal_cards(nth, [player1, player2], deck) do
    {card, newDeck} = Deck.draw(deck)
    Player.deal_card(player1, card)
    deal_cards(nth - 1, [player2, player1], newDeck)
  end

  defp end_the_game(gameName, currentPlayer, nextPlayer) do
    score = Player.end_game(currentPlayer)
    score2 = Player.end_game(nextPlayer)
    cond do
      score > score2 -> Logger.debug("[#{gameName}] Player #{currentPlayer} wins with #{score} over #{score2}!")
      score < score2 -> Logger.debug("[#{gameName}] Player #{nextPlayer} wins with #{score2} over #{score}!")
      score == score2 -> Logger.debug("[#{gameName}] It's a draw!")
    end
  end

  defp report(callback, midCards, []) do
    callback.(:new_mid_cards, midCards)
    callback.(:new_discards, [])    
  end
  defp report(callback, midCards, newDiscard) do
    callback.(:new_mid_cards, midCards)
    callback.(:new_discards, [hd(newDiscard)])    
  end
end
