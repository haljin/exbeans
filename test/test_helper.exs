ExUnit.start()

defmodule StatemTest.Macro do
  defmacro assert_state(stateName, for: process) do
      quote do
        {actualState, _} = :sys.get_state(unquote(process)); assert unquote(stateName) == actualState
      end
    end
end
