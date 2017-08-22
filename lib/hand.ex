defmodule ExBeans.Hand do
  @moduledoc """
  This data structure represents the cards held by a player in the game of Bohnanza

  ## Examples

      iex> Hand.new()
      []

      iex> hand = Hand.new(); Hand.add_card(%Beans.GreenBean{}, hand)
      [%Beans.GreenBean{}]

      iex> Hand.add_card(%Beans.BlueBean{}, [%Beans.GreenBean{}])
      [%Beans.GreenBean{}, %Beans.BlueBean{}]

      iex> Hand.play_card([%Beans.GreenBean{}, %Beans.BlueBean{}])
      {%Beans.GreenBean{}, [%Beans.BlueBean{}]}

      iex> Hand.discard_card([%Beans.GreenBean{}, %Beans.BlueBean{}, %Beans.WaxBean{}], 1)
      {%Beans.BlueBean{}, [%Beans.GreenBean{}, %Beans.WaxBean{}]}
  """

  @typedoc "The cards held in a player's hand"
  @type hand :: list(ExBeans.Beans.bean())

  @doc "Create a new empty hand of Bohnanza cards."
  @spec new() :: hand
  def new() do
    []
  end

  @doc "Add a card to a hand of cards. It will be added at the end."
  @spec add_card(Beans.bean, hand) :: hand
  def add_card(card, hand) do
    hand ++ [card]
  end

  @doc "Remove the first card in the hand so it can be played. There must be at least one card in the hand."
  @spec play_card(hand) :: hand
  def play_card(hand) when length(hand) > 0 do
    [toPlay | rest] = hand
    {toPlay, rest}
  end

  @doc "Discard the card at the specified position."
  @spec discard_card(hand, non_neg_integer) :: hand
  def discard_card(hand, index) do
    List.pop_at(hand, index)
  end
end