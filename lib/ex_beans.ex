defmodule ExBeans do
  @moduledoc false
  
  use Application

  def start(_type, _args) do
    ExBeansSup.Supervisor.start_link()
  end
end