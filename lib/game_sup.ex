defmodule ExBeans.Game.Supervisor do
  @moduledoc false
  
  use Supervisor
  alias ExBeans.Player
  alias ExBeans.BeanGame

  def start_link(gameName) do
    Supervisor.start_link(__MODULE__, [gameName])
  end
  def start_link(gameName, player1Name, player2Name) do
    Supervisor.start_link(__MODULE__, [gameName, player1Name, player2Name])
  end

  def new_player(pid, name) do
    if length(Supervisor.which_children(pid)) < 3 do
      Supervisor.start_child(pid, worker(Player, [name], id: name, restart: :permanent))
    else 
      {:error, :player_limit_reached}
    end    
  end

  def init([gameName, player1Name, player2Name]) do
    children = [
      worker(Player, [player1Name], id: :player1, restart: :permanent),
      worker(Player, [player2Name], id: :player2, restart: :permanent),
      worker(BeanGame, [gameName], restart: :permanent)
    ]

    supervise(children, strategy: :one_for_all)
  end
  def init([gameName]) do
    children = [
      worker(BeanGame, [gameName], restart: :permanent)
    ]

    supervise(children, strategy: :one_for_all)
  end

end