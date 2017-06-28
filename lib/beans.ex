    defmodule Beans do
      @moduledoc false
      @type bean :: %Beans.GreenBean{} | %Beans.CoffeeBean{}

  defmodule GreenBean do
    @moduledoc false
    defstruct  name: "Green Bean"
  end

  defmodule CoffeeBean do
    @moduledoc false
    defstruct  name: "Coffee Bean"
  end

end