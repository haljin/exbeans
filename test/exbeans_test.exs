defmodule ExbeansTest do
  use ExUnit.Case
  doctest Exbeans

  test "greets the world" do
    assert Exbeans.hello() == :world
  end
end
