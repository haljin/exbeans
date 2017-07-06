defmodule BeanFieldTest do
  use ExUnit.Case
  @moduledoc false


  test "Simple planting" do
    field = BeanField.new()

    field = %{1 => beans} = BeanField.plant_bean(field, 1, %Beans.GreenBean{})
    assert length(beans) == 1
    assert Enum.all?(beans, &(&1 == %Beans.GreenBean{}))

    field = %{1 => beans} = BeanField.plant_bean(field, 1, %Beans.GreenBean{})
    assert length(beans) == 2
    assert Enum.all?(beans, &(&1 == %Beans.GreenBean{}))

    field = BeanField.plant_bean(field, 2, %Beans.BlackEyedBean{})
    {:error, :not_allowed} = BeanField.plant_bean(field, 1, %Beans.BlackEyedBean{})
    {:error, :not_allowed} = BeanField.plant_bean(field, 2, %Beans.GreenBean{})
  end


  test "One field test" do
    field = BeanField.new()

    field = BeanField.plant_bean(field, 1, %Beans.GreenBean{})
    {:error, :not_allowed} = BeanField.harvest_field(field, 1)
    field = BeanField.plant_bean(field, 1, %Beans.GreenBean{})

    {field, {[], [%Beans.GreenBean{},%Beans.GreenBean{}]}} = BeanField.harvest_field(field, 1)


    field = BeanField.plant_bean(field, 1, %Beans.GreenBean{})
    field = BeanField.plant_bean(field, 1, %Beans.GreenBean{})
    field = BeanField.plant_bean(field, 1, %Beans.GreenBean{})
    field = BeanField.plant_bean(field, 1, %Beans.GreenBean{})

    {_field, {[%Beans.GreenBean{}], [%Beans.GreenBean{}, %Beans.GreenBean{},%Beans.GreenBean{}]}}
    = BeanField.harvest_field(field, 1)
  end

  test "Two field test" do
    planting_on_two_fields(1,2)
    planting_on_two_fields(2,1)
  end

  test "Third field" do
    field = BeanField.new()
    assert_raise(CaseClauseError, fn -> BeanField.plant_bean(field, 3, %Beans.CoffeeBean{}) end)

    field = BeanField.buy_field(field)
    %{3 => beans} = BeanField.plant_bean(field, 3, %Beans.CoffeeBean{})
    assert length(beans) == 1
    assert Enum.all?(beans, &(&1 == %Beans.CoffeeBean{}))
  end

  test "Three field test" do
    planting_on_three_fields(1,2,3)
    planting_on_three_fields(1,3,2)
    planting_on_three_fields(2,1,3)
    planting_on_three_fields(2,3,1)
    planting_on_three_fields(3,1,2)
    planting_on_three_fields(3,2,1)
  end

  defp planting_on_two_fields(firstField, secondField) do
    field = BeanField.new()
    field = BeanField.plant_bean(field, firstField, %Beans.GreenBean{})
    {:error, :not_allowed} = BeanField.harvest_field(field, firstField)

    field = BeanField.plant_bean(field, secondField, %Beans.BlackEyedBean{})
    {_field, {[], [%Beans.GreenBean{}]}} = BeanField.harvest_field(field, firstField)

  end

  defp planting_on_three_fields(firstField, secondField, thirdField) do
    field = BeanField.new()
    field = BeanField.buy_field(field)

    field = BeanField.plant_bean(field, firstField, %Beans.GreenBean{})
    field = BeanField.plant_bean(field, secondField, %Beans.BlackEyedBean{})

    {:error, :not_allowed} = BeanField.harvest_field(field, firstField)
    field = BeanField.plant_bean(field, thirdField, %Beans.CoffeeBean{})

    {_field, {[], [%Beans.GreenBean{}]}} = BeanField.harvest_field(field, firstField)
  end


end