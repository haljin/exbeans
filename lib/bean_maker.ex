defmodule BeanMaker do
  @moduledoc false

  defmacro defbean(beanType, firstLevel, secondLevel, thirdLevel, fourthLevel) do
    quote do
      defmodule unquote(beanType) do
        defstruct name: Atom.to_string(unquote(beanType))
      end

      defimpl Beans.Bean, for: unquote(beanType) do
        def harvest(_bean, beans) do
          cond do
            length(beans) > unquote fourthLevel -> Enum.split(beans, 4)
            length(beans) > unquote thirdLevel -> Enum.split(beans, 3)
            length(beans) > unquote secondLevel -> Enum.split(beans, 2)
            length(beans) > unquote firstLevel -> Enum.split(beans, 1)
            true -> {[], beans}
          end
        end
      end
    end
  end
end