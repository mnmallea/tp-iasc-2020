defmodule PigeonTest do
  use ExUnit.Case
  doctest Pigeon

  test "greets the world" do
    assert Pigeon.hello() == :world
  end
end
