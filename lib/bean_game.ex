defmodule BeanGame do
  @moduledoc false
  @type gameName :: atom

  defmodule Behaviour do
    @callback register_player(BeanGame.gameName, Player.playerName) :: :ok
    @callback discard_cards(BeanGame.gameName, [Beans.bean]) :: :ok
    @callback get_mid_cards(BeanGame.gameName) :: [Beans.bean]
    @callback new_mid_cards(BeanGame.gameName) :: :ok
    @callback get_mid_card(BeanGame.gameName, integer) :: {:ok, Beans.bean} | {:error, :invalid_card}
    @callback remove_mid_card(BeanGame.gameName, integer) :: :ok | {:error, :invalid_card}
    @callback player_done(BeanGame.gameName) :: :ok
  end
  
  defmodule Game do
  @behaviour BeanGame.Behaviour
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
      GenServer.cast(gameName, {:remove_mid_card, index})
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
      {:reply, :ok, %State{state | players: playerOrder, deck: deckAfterDealing}}
    end
    def handle_call(:get_mid_cards, _from, %State{extra_cards: bonus} = state) do
      {:reply, bonus, state}
    end

    def handle_cast({:discard, cards}, %State{discard: disc} = state) do
      {:noreply, %State{state | discard: cards ++ disc}}
    end

    defp deal_cards(0, _, deck) do
      deck
    end
    defp deal_cards(nth, [player1, player2], deck) do
      {card, newDeck} = Deck.draw(deck)
      Player.deal_card(player1, card)
      deal_cards(nth - 1, [player2, player1], newDeck)
    end
  end
end