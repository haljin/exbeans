defmodule Games.Supervisor do
  @moduledoc false
  
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_game(name) do
    Supervisor.start_child(__MODULE__, [name])
  end

  def init([]) do
    children = [
      worker(BeanGame.Game, [], restart: :transient)
    ]
    supervise(children, strategy: :simple_one_for_one)
  end
end