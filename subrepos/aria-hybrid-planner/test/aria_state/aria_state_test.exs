# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStateTest do
  use ExUnit.Case
  doctest AriaState

  test "main module works directly" do
    state =
      AriaState.new()
      |> AriaState.set_fact("chef_1", "status", "cooking")

    assert AriaState.get_fact(state, "chef_1", "status") == {:ok, "cooking"}
  end

  test "converts between state formats" do
    state =
      AriaState.new()
      |> AriaState.set_fact("chef_1", "status", "cooking")

    relational_state = AriaState.convert(state)
    assert %AriaState.RelationalState{} = relational_state

    converted_back = AriaState.convert(relational_state)
    assert %AriaState{} = converted_back
    assert AriaState.get_fact(converted_back, "chef_1", "status") == {:ok, "cooking"}
  end
end
