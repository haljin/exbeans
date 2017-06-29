defmodule Player do
  @moduledoc false
  use GenServer

  defmodule State do
    defstruct name: nil, game: nil, hand: Hand.new()
  end

## API

  def start_link(name) do
    GenServer.start_link(__MODULE__, [name], name: name)
  end

  def join_game(name, gameName) do
    GenServer.call(name, {:join_game, gameName})
  end

  def deal_card(name, card) do
    GenServer.cast(name, {:deal_card, card})
  end

  def get_hand(name) do
    GenServer.call(name, :get_hand)
  end

##  GenServer callbacks

  def init([name]) do
    {:ok, %Player.State{name: name}}
  end

  def handle_call({:join_game, gameName}, _from, %Player.State{name: name} = state) do
    :ok = BeanGame.register_player(gameName, name)
    {:reply, :ok, state}
  end
  def handle_call(:get_hand, _from, %Player.State{hand: hand} = state) do
    {:reply, hand, state}
  end

  def handle_cast({:deal_card, card}, %Player.State{hand: hand} = state) do
    {:noreply, %Player.State{state | hand: Hand.add_card(card, hand)}}
  end
end