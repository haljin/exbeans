defmodule BeanGame.Mock do
  @moduledoc false
  @behaviour BeanGame.Behaviour

  def init() do
    :ets.new(:testGameTable, [:set, :public, :named_table])
  end

  def register_player(_, _) do
    :ok
  end

  def discard_cards(_, _) do
    :ok
  end

  def get_mid_cards(gameName) do
    case :ets.lookup(:testGameTable, gameName) do
      [] -> []
      [{^gameName, list}] -> list
    end
  end

  def new_mid_cards(_) do
    :ok
  end

  def set_mid_cards(gameName, list) do
    :ets.insert(:testGameTable, {gameName, list})
  end

  def get_mid_card(gameName, index) do
    [{^gameName, list}] = :ets.lookup(:testGameTable, gameName)
    case Enum.at(list, index) do
      nil -> {:error, :invalid_card}
      elem -> {:ok, elem}
    end
  end

  def remove_mid_card(gameName, index) do
    [{^gameName, list}] = :ets.lookup(:testGameTable, gameName)
    newList = List.delete_at(list, index)
    :ets.insert(:testGameTable, {gameName, newList})
    :ok
  end

  def player_done(_) do
    :ok
  end

end