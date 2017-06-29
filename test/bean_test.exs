defmodule BeanTest do
  use ExUnit.Case
  @moduledoc false


  test "Deck" do
    deck = Deck.new()
    assert length(deck) == 90
    onlygreens = for %Beans.GreenBean{} = card <- deck do card end
    rest = deck -- onlygreens
    assert length(onlygreens) == 14
    assert Enum.all?(rest,  fn
                                (%Beans.GreenBean{}) -> false
                                (_) -> true
                            end)
  end

  test "Deck drawing" do
    iterator = Enum.into(1..90, [])
    finaldeck = List.foldl(iterator, Deck.new(), fn(_, deck) -> {_, newdeck} = Deck.draw(deck); newdeck end)
    :empty = Deck.draw(finaldeck)
  end

  test "Hand tests" do
    hand = Hand.new()
    createdHand = Hand.add_card(%Beans.GreenBean{}, Hand.add_card(%Beans.CoffeeBean{}, hand))
    {%Beans.CoffeeBean{}, restHand} = Hand.play_card(createdHand)
    {%Beans.GreenBean{}, emptyHand} = Hand.play_card(restHand)

    assert_raise(FunctionClauseError, fn -> Hand.play_card(emptyHand) end)
  end

  test "Field tests" do
    field = BeanField.new()

    field = %{1 => beans} = BeanField.plant_bean(field, 1, %Beans.GreenBean{})
    assert length(beans) == 1
    assert Enum.all?(beans, &(&1 == %Beans.GreenBean{}))

    field = %{1 => beans} = BeanField.plant_bean(field, 1, %Beans.GreenBean{})
    assert length(beans) == 2
    assert Enum.all?(beans, &(&1 == %Beans.GreenBean{}))

    {field, {[], _}} = {%{1 => beans}, _} = BeanField.plant_bean(field, 1, %Beans.BlackEyedBean{})
    assert length(beans) == 1
    assert Enum.all?(beans, &(&1 == %Beans.BlackEyedBean{}))

    assert_raise(CaseClauseError, fn -> BeanField.plant_bean(field, 3, %Beans.CoffeeBean{}) end)

    field = BeanField.buy_field(field)
    %{3 => beans} = BeanField.plant_bean(field, 3, %Beans.CoffeeBean{})
    assert length(beans) == 1
    assert Enum.all?(beans, &(&1 == %Beans.CoffeeBean{}))
  end

  test "Scoring test" do
    field = BeanField.new()
    planted = List.foldl(Enum.into(1..5, []), field, fn(_, f) -> BeanField.plant_bean(f, 1, %Beans.BlueBean{}) end)
    {_, {score, _}} = BeanField.harvest_field(planted, 1)
    assert length(score) == 1

    planted = List.foldl(Enum.into(1..8, []), field, fn(_, f) -> BeanField.plant_bean(f, 1, %Beans.BlueBean{}) end)
    {_, {score, _}} = BeanField.harvest_field(planted, 1)
    assert length(score) == 3

    planted = List.foldl(Enum.into(1..100, []), field, fn(_, f) -> BeanField.plant_bean(f, 1, %Beans.BlueBean{}) end)
    {_, {score, _}} = BeanField.harvest_field(planted, 1)
    assert length(score) == 4
  end

end