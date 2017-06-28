defmodule Deck do
  @moduledoc false

  @type deck :: list(Beans.bean())

  @spec new() :: deck()
  def new() do
    greenBeans = for _n <- 1..14 do %Beans.GreenBean{} end
    coffeeBeans = for _n <- 1..24 do %Beans.CoffeeBean{} end

    Enum.shuffle(greenBeans ++ coffeeBeans)
  end

  @spec draw(deck()) :: {Beans.bean(), deck()}
  def draw([]) do
    :empty
  end
  def draw(deck) do
    [card | rest] = deck
    {card, rest}
  end

  @spec shuffle(deck()) :: deck()
  def shuffle(deck) do
    Enum.shuffle(deck)
  end

  @spec add_to_deck(Beans.bean() | list(Beans.bean()), deck()) :: deck()
  def add_to_deck(beans, deck) when is_list(beans) do
    deck ++ beans
  end
  def add_to_deck(bean, deck) do
    deck ++ [bean]
  end


end