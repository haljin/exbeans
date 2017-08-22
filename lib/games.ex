defmodule ExBeans.Games.Supervisor do
  @moduledoc false
  
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_game(name, player1Name, player2Name) do
    Supervisor.start_child(__MODULE__, [name, player1Name, player2Name])
  end


  def init([]) do
    children = [
      supervisor(ExBeans.Game.Supervisor, [], restart: :temporary)
    ]
    supervise(children, strategy: :simple_one_for_one)
  end
end