defmodule Hand do
  @moduledoc false

  @type hand :: list(Beans.bean())

  def new() do
    []
  end

  def add_card(card, hand) do
    hand ++ [card]
  end

  def play_card(hand) when length(hand) > 0 do
    [toPlay | rest] = hand
    {toPlay, rest}
  end

  def discard_card(hand, index) do
    List.pop_at(hand, index)
  end

  def see(hand) do
    for card <- hand do IO.puts inspect card end
  end

end