defmodule ExBeansSup.Supervisor do
  @moduledoc false
  
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [
      supervisor(Games.Supervisor, [], restart: :permanent),
      supervisor(Players.Supervisor, [], restart: :permanent)
    ]

    supervise(children, strategy: :one_for_all)
  end
end