defmodule BeanTest do
  use ExUnit.Case
  @moduledoc false

  test "GreenBean" do
    bean = %Beans.GreenBean{}
    assert bean.name == "Green Bean"
  end

  test "CoffeeBean" do
      bean = %Beans.CoffeeBean{}
      assert bean.name == "Coffee Bean"
  end

  test "Deck" do
    deck = Deck.new()
    assert length(deck) == 38
    onlygreens = for %Beans.GreenBean{} = card <- deck do card end
    rest = deck -- onlygreens
    assert length(onlygreens) == 14
    assert length(rest) == 24
    assert Enum.all?(rest,  fn
                                (%Beans.CoffeeBean{}) -> true
                                (_) -> false
                            end)
  end

  test "Deck drawing" do
    iterator = Enum.into(1..38, [])
    finaldeck = List.foldl(iterator, Deck.new(), fn(_, deck) -> {_, newdeck} = Deck.draw(deck); newdeck end)
    :empty = Deck.draw(finaldeck)
  end
  
end