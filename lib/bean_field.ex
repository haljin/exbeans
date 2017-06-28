defmodule BeanField do
  @moduledoc false

  def new() do
    %{1 => [], 2 => []}
  end

  def harvest_field(field, index) do
    beans = field[index]
    {%{field | index => []}, Beans.Bean.harvest(hd(beans), beans)}
  end

  def plant_bean(field, index, bean) do
    case field[index] do
      [] -> %{field | index => [bean]}
      [^bean|_] = beans -> %{field | index => [bean | beans]}
      [_|_] ->  {harvested, harvestResult} = harvest_field(field, index)
                {%{harvested | index => [bean]}, harvestResult}
    end
  end

  def buy_field(field) do
    cond do
      field[3] == nil -> Map.put(field, 3, [])
    end
  end


end