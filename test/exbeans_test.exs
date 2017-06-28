defmodule ExbeansTest do
  use ExUnit.Case
  doctest Exbeans

  test "greets the world" do
    assert Exbeans.hello() == :world
  end

  test "Data types" do
    assert is_integer(12)
    assert is_float(1.0)
    assert is_atom(:testing)
    assert is_boolean(true)
    assert :true == true

    assert 1 == 1.0
    refute 1 === 1.0

    assert is_tuple({:test, 12})
    assert is_list([1,2,3])
  end

  test "Binary types" do
    binary = <<12, 13, 3>>
    bitstring = <<15, 3 :: size(3)>>
    assert is_binary(binary)
    assert is_bitstring(binary)
    assert is_bitstring(bitstring)
    refute is_binary(bitstring)
  end

  test "Strings" do
    assert is_binary("Test")
    assert is_list('test')

    assert "Concatenated text" == "Concatenated " <> "text"

  end

  test "Lists" do
    assert [1,2,3,4,5] == [1,2,3] ++ [4,5]
    assert [1,2,3] == [1,2,3,4,5] -- [4,5]
    [match, 2] = [1,2]
    assert match == 1

    [head | tail] = [1,2,3,4]
    assert head == 1
    assert tail == [2,3,4]
  end

  test "Keyword lists" do
    keywords = [a: 1, b: 2]
    1 = keywords[:a]
    assert [{:a, 1}, {:b, 2}] == keywords
    newkeywords = [a: 5] ++ keywords
    assert newkeywords[:a] == 5
  end

  test "Maps" do
    map = %{:a => 1}
    assert is_map(map)
    assert map[:a] == 1
    assert map.a == 1

    %{a: value} = map
    assert value == 1

    assert %{a: 1} == %{:a => 1}

    newmap = %{map | a: 2}
    assert newmap[:a] == 2
  end

  test "Special types" do
    pid = self()
    IO.puts inspect pid
    assert is_pid(pid)
    ref = make_ref()
    IO.puts inspect ref
    assert is_reference(ref)
  end




end
