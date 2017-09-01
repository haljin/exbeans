defmodule ExBeans.Games.Supervisor do
  @moduledoc false
  
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end
  
  def start_game(name) do
    {:ok, pid} = Supervisor.start_child(__MODULE__, [name])
    children = Supervisor.which_children(pid)
    [sup: pid, game: get_child_pid(ExBeans.BeanGame, children)]
  end

  def start_game(name, player1Name, player2Name) do
    {:ok, pid} = Supervisor.start_child(__MODULE__, [name, player1Name, player2Name])
    children = Supervisor.which_children(pid)
    [sup: pid, game: get_child_pid(ExBeans.BeanGame, children), player1: get_child_pid(:player1, children), player2: get_child_pid(:player2, children)]
  end

  def stop_game(pid) do
    Supervisor.terminate_child(__MODULE__, pid)
  end

  def init([]) do
    children = [
      supervisor(ExBeans.Game.Supervisor, [], restart: :temporary)
    ]
    supervise(children, strategy: :simple_one_for_one)
  end
  
  defp get_child_pid(childName, children) do
    {_, pid, _, _} = List.keyfind(children, childName, 0)
    pid
  end
end

 
