defmodule Beans do
  require BeanMaker
  import BeanMaker
  @moduledoc false
  @type bean :: %Beans.GreenBean{} | %Beans.CoffeeBean{} | %Beans.BlueBean{} | %Beans.WaxBean{} | %Beans.BlackEyedBean{}

  defmodule GreenBean do
    @moduledoc false
    defstruct  name: "Green Bean"
  end

  defmodule CoffeeBean do
    @moduledoc false
    defstruct  name: "Coffee Bean"
  end

 defmodule BlueBean do
    @moduledoc false
    defstruct  name: "Blue Bean"
  end

 defmodule WaxBean do
   @moduledoc false
   defstruct  name: "Wax Bean"
 end

 defmodule BlackEyedBean do
   @moduledoc false
   defstruct  name: "Black Eyed Bean"
 end

 defprotocol Bean do
   def harvest(bean, beanList)
 end


end





defimpl Beans.Bean, for: Beans.GreenBean do
  def harvest(_bean, beans) do
    cond do
      length(beans) > 7 -> Enum.split(beans, 4)
      length(beans) > 6 -> Enum.split(beans, 3)
      length(beans) > 5 -> Enum.split(beans, 2)
      length(beans) > 3 -> Enum.split(beans, 1)
      true -> {[], beans}
    end
  end
end

defimpl Beans.Bean, for: Beans.CoffeeBean do
  def harvest(_bean, beans) do
    cond do
      length(beans) > 12 -> Enum.split(beans, 4)
      length(beans) > 10 -> Enum.split(beans, 3)
      length(beans) > 7 -> Enum.split(beans, 2)
      length(beans) > 4 -> Enum.split(beans, 1)
      true -> {[], beans}
    end
  end
end

defimpl Beans.Bean, for: Beans.WaxBean do
  def harvest(_bean, beans) do
    cond do
      length(beans) > 11 -> Enum.split(beans, 4)
      length(beans) > 9 -> Enum.split(beans, 3)
      length(beans) > 7 -> Enum.split(beans, 2)
      length(beans) > 4 -> Enum.split(beans, 1)
      true -> {[], beans}
    end
  end
end

defimpl Beans.Bean, for: Beans.BlueBean do
  def harvest(_bean, beans) do
    cond do
      length(beans) > 10 -> Enum.split(beans, 4)
      length(beans) > 8 -> Enum.split(beans, 3)
      length(beans) > 6 -> Enum.split(beans, 2)
      length(beans) > 4 -> Enum.split(beans, 1)
      true -> {[], beans}
    end
  end
end

defimpl Beans.Bean, for: Beans.BlackEyedBean do
  def harvest(_bean, beans) do
    cond do
      length(beans) > 6 -> Enum.split(beans, 4)
      length(beans) > 5 -> Enum.split(beans, 3)
      length(beans) > 4 -> Enum.split(beans, 2)
      length(beans) > 2 -> Enum.split(beans, 1)
      true -> {[], beans}
    end
  end
end