defmodule BeanGame do
  @moduledoc false
  
  use GenServer
  defmodule State do
    defstruct name: nil, deck: Deck.new(), discard: [], players: nil, extra_cards: []
  end

## API

  def start_link(gameName) do
    GenServer.start_link(__MODULE__, [gameName], name: gameName)
  end

  def register_player(gameName, player) do
    GenServer.call(gameName, {:register, player})
  end

##  GenServer callbacks

  def init([gameName]) do
    IO.puts "New game of Bohnanza started #{gameName}!"
    IO.puts "[#{gameName}] Waiting for players"

    {:ok, %BeanGame.State{name: gameName}}
  end

  def handle_call({:register, player}, _from, %BeanGame.State{name: gameName, players: nil} = state) do
    IO.puts "[#{gameName}] Registered player: #{player}"
    {:reply, :ok, %BeanGame.State{state | players: [player]}}
  end
  def handle_call({:register, player2}, _from, %BeanGame.State{name: gameName, players: [player1], deck: deck} = state) do
    IO.puts "[#{gameName}] Registered player: #{player2}"
    playerOrder = Enum.shuffle([player1, player2])
    deckAfterDealing = deal_cards(length(playerOrder) * 5, playerOrder, deck)
    IO.puts "[#{gameName}] Starting game: #{player1} vs. #{player2}. #{hd(playerOrder)} will start!"
    {:reply, :ok, Map.merge(%BeanGame.State{state | players: playerOrder}, %BeanGame.State{deck: deckAfterDealing})}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  defp deal_cards(0, [player1, player2], deck) do
      deck
  end
  defp deal_cards(nth, [player1, player2], deck) do
    {card, newDeck} = Deck.draw(deck)
    Player.deal_card(player1, card)
    deal_cards(nth - 1, [player2, player1], newDeck)
  end

end