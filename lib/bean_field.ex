defmodule BeanField do
  @moduledoc """
  Implements Bohnanza player's bean fields. Provides various API for planting new beans and harvesting them.
  """

  @typedoc "The player's bean fields."
  @type beanField :: %{}
  @typedoc "Index of the particular bean field."
  @type beanFieldIndex :: 1..3

  @doc "Creates a new bean field structure"
  @spec new() :: beanField()
  def new() do
    %{1 => [], 2 => [], 3 => :not_available}
  end

  @doc "Harvests the specified field if it is a legal move. Returns {:error, :not_allowed} otherwise"
  @spec harvest_field(beanField(), beanFieldIndex) ::  {beanField, {[Beans.bean()], [Beans.bean()]}} | {:error, :not_allowed}
  def harvest_field(field, index) do
    case field[index] do
      [] -> {field, {[], []}}
      [_bean] -> check_and_maybe_harvest(index, field)
      beans when length(beans) > 1 -> harvest(field, index)
    end
  end

  @doc "Plants a bean card at the specified field if it is a legal move. Returns {:error, :not_allowed} otherwise"
  @spec plant_bean(beanField(), beanFieldIndex, Beans.bean()) :: {:ok, beanField()} | {:error, :not_allowed}
  def plant_bean(field, index, bean) do
    case field[index] do
      [] -> %{field | index => [bean]}
      [^bean|_] = beans -> %{field | index => [bean | beans]}
      beans when is_list(beans) -> {:error, :not_allowed}
    end
  end

  @doc "Allows the player to purchase the third bean field"
  @spec buy_field(beanField()) :: beanField()
  def buy_field(%{3 => :not_available} = field) do
    %{field | 3 => []}
  end

  defp check_and_maybe_harvest(1, field = %{2 => [_someBean], 3 => third}) when third == :not_available or length(third) == 1  do
     harvest(field, 1)
  end
  defp check_and_maybe_harvest(2, field = %{1 => [_someBean], 3 => third}) when third == :not_available or length(third) == 1 do
     harvest(field, 2)
  end
  defp check_and_maybe_harvest(3, field = %{1 => [_someBean], 2 => [_someOtherBean]}) do
     harvest(field, 3)
  end
  defp check_and_maybe_harvest(_, _) do
     {:error, :not_allowed}
  end

  defp harvest(field, index) do
    beans = field[index]
    {%{field | index => []}, Beans.Bean.harvest(hd(beans), beans)}
  end

end