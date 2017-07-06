defmodule Deck do
  @moduledoc """
  This modules allows for creation and manipulation of a deck of Bohnanza cards
  """

  @typedoc "A deck of Bohnanza cards."
  @type deck :: list(Beans.bean())

  @doc "Creates a new, shuffled deck of Bohnanza cards"
  @spec new() :: deck()
  def new() do
    generate_beans() |>
    List.flatten |>
    Enum.shuffle
  end

  @doc "Draw a card from the deck"
  @spec draw(deck()) :: {Beans.bean(), deck()} | :empty
  def draw([]) do
    :empty
  end
  def draw(deck) do
    [card | rest] = deck
    {card, rest}
  end

  @doc "Shuffle the deck again"
  @spec shuffle(deck()) :: deck()
  def shuffle(deck) do
    Enum.shuffle(deck)
  end

  @doc "Add a new card or list of cards at the end of the deck"
  @spec add_to_deck(Beans.bean() | list(Beans.bean()), deck()) :: deck()
  def add_to_deck(beans, deck) when is_list(beans) do
    deck ++ beans
  end
  def add_to_deck(bean, deck) do
    deck ++ [bean]
  end

  defp generate_beans() do
    allBeans = [%Beans.CoffeeBean{},  %Beans.WaxBean{},  %Beans.BlueBean{},  %Beans.ChiliBean{},  %Beans.StinkBean{},
    %Beans.GreenBean{},  %Beans.SoyBean{},  %Beans.BlackEyedBean{},  %Beans.RedBean{}]
    for beanType <- allBeans do List.duplicate(beanType, Beans.Bean.count(beanType)) end
  end

end