defmodule BeanGame do
  @moduledoc false
  @type gameName :: atom
#
#  defmodule Behaviour do
#    @callback register_player(BeanGameName, Player.playerName) :: :ok
#    @callback discard_cards(BeanGameName, [Beans.bean]) :: :ok
#    @callback get_mid_cards(BeanGameName) :: [Beans.bean]
#    @callback new_mid_cards(BeanGameName) :: :ok
#    @callback get_mid_card(BeanGameName, integer) :: {:ok, Beans.bean} | {:error, :invalid_card}
#    @callback remove_mid_card(BeanGameName, integer) :: :ok | {:error, :invalid_card}
#    @callback player_done(BeanGameName) :: :ok
#  end
  use GenServer
    defmodule State do
      defstruct name: nil, deck: Deck.new(), discard: [], players: nil, extra_cards: [], game_over: false
    end

## API
  def start_link(gameName) do
    GenServer.start_link(__MODULE__, [gameName], name: gameName)
  end

  def register_player(gameName, player) do
    GenServer.call(gameName, {:register, player})
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

##  GenServer callbacks

  def init([gameName]) do
    IO.puts "New game of Bohnanza started #{gameName}!"
    IO.puts "[#{gameName}] Waiting for players"

    {:ok, %State{name: gameName}}
  end

  def handle_call({:register, player}, _from, %State{name: gameName, players: nil} = state) do
    IO.puts "[#{gameName}] Registered player: #{player}"
    {:reply, :ok, %State{state | players: [player]}}
  end
  def handle_call({:register, player2}, _from, %State{name: gameName, players: [player1], deck: deck} = state) do
    IO.puts "[#{gameName}] Registered player: #{player2}"
    playerOrder = Enum.shuffle([player1, player2])
    deckAfterDealing = deal_cards(length(playerOrder) * 5, playerOrder, deck)
    IO.puts "[#{gameName}] Starting game: #{player1} vs. #{player2}. #{hd(playerOrder)} will start!"
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

  def handle_cast({:discard, cards}, %State{discard: disc} = state) do
    {:noreply, %State{state | discard: cards ++ disc}}
  end
  def handle_cast(:new_bonus_cards, %State{deck: deck, discard: discard} = state) do
     case draw_cards(3, deck, []) do
       {[], newMid} ->
         {midWithDiscard, newDiscard} = fill_discard(newMid, discard)
         {:noreply, %State{state | extra_cards: midWithDiscard, discard: newDiscard, game_over: true}}
       {newDeck, newMid} ->
         {midWithDiscard, newDiscard} = fill_discard(newMid, discard)
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
      score > score2 -> IO.puts("[#{gameName}] Player #{currentPlayer} wins with #{score} over #{score2}!")
      score < score2 -> IO.puts("[#{gameName}] Player #{nextPlayer} wins with #{score2} over #{score}!")
      score == score2 -> IO.puts("[#{gameName}] It's a draw!")
    end
  end
end