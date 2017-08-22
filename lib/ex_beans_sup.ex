defmodule ExBeans.ExBeansSup.Supervisor do
  @moduledoc false
  
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [
      supervisor(ExBeans.Games.Supervisor, [], restart: :permanent)
    ]

    supervise(children, strategy: :one_for_all)
  end
end