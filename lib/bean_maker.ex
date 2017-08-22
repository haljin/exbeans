defmodule ExBeans.BeanMaker do
  @moduledoc ~S"""
  Allows defining new bean types.

  `BeanMaker` contains a macro that allows for easy definition of additional bean types.
  """

  @doc """
  Define a new bean type given three parameters.

  The name of the new bean, the amount of such beans in the deck
  and the four levels of the bean-o-meter. The bean will automatically implement the `Beans.Bean` protocol.

  ## Examples
  `defbean CoffeeBean,    count: 24,  levels: [4, 7, 10, 12]`
  """
  defmacro defbean(beanType, count: count, levels: [firstLevel, secondLevel, thirdLevel, fourthLevel]) do
    quote do
      defmodule unquote(beanType) do
        @moduledoc false
        defstruct name: Atom.to_string(unquote(beanType))
      end

      defimpl ExBeans.Beans.Bean, for: unquote(beanType) do
        def harvest(_bean, beans) do
          cond do
            length(beans) >= unquote fourthLevel -> Enum.split(beans, 4)
            length(beans) >= unquote thirdLevel -> Enum.split(beans, 3)
            length(beans) >= unquote secondLevel -> Enum.split(beans, 2)
            length(beans) >= unquote firstLevel -> Enum.split(beans, 1)
            true -> {[], beans}
          end
        end

        def count(bean) do
          unquote(count)
        end
      end
    end
  end
end