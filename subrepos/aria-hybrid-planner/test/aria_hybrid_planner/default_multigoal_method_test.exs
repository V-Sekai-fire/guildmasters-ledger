# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.DefaultMultigoalMethodTest do
  use ExUnit.Case, async: true
  doctest AriaCore.DefaultMultigoalMethod

  alias AriaCore.DefaultMultigoalMethod

  describe "default_multigoal_method/2" do
    test "returns empty list when all goals are achieved" do
      state = AriaState.new()
      state = AriaState.set_fact(state, "pos", "a", "table")
      state = AriaState.set_fact(state, "pos", "b", "table")

      multigoal = %{goals: [{"pos", "a", "table"}, {"pos", "b", "table"}]}

      result = DefaultMultigoalMethod.default_multigoal_method(state, multigoal)
      assert result == []
    end

    test "returns [goal, multigoal] when first goal is unachieved" do
      state = AriaState.new()
      state = AriaState.set_fact(state, "pos", "a", "table")

      multigoal = %{goals: [{"pos", "a", "b"}, {"pos", "b", "table"}]}

      result = DefaultMultigoalMethod.default_multigoal_method(state, multigoal)
      assert result == [{"pos", "a", "b"}, multigoal]
    end

    test "returns first unachieved goal when multiple goals are unachieved" do
      state = AriaState.new()

      multigoal = %{goals: [{"pos", "a", "b"}, {"pos", "b", "c"}, {"pos", "c", "table"}]}

      result = DefaultMultigoalMethod.default_multigoal_method(state, multigoal)
      assert result == [{"pos", "a", "b"}, multigoal]
    end

    test "skips achieved goals and returns first unachieved goal" do
      state = AriaState.new()
      state = AriaState.set_fact(state, "pos", "a", "table")
      state = AriaState.set_fact(state, "clear", "a", true)

      multigoal = %{goals: [{"pos", "a", "table"}, {"clear", "a", true}, {"pos", "b", "c"}]}

      result = DefaultMultigoalMethod.default_multigoal_method(state, multigoal)
      assert result == [{"pos", "b", "c"}, multigoal]
    end

    test "handles empty goals list" do
      state = AriaState.new()
      multigoal = %{goals: []}

      result = DefaultMultigoalMethod.default_multigoal_method(state, multigoal)
      assert result == []
    end
  end

  describe "find_unachieved_goal/2" do
    test "returns nil when all goals are achieved" do
      state = AriaState.new()
      state = AriaState.set_fact(state, "pos", "a", "table")
      state = AriaState.set_fact(state, "pos", "b", "table")

      goals = [{"pos", "a", "table"}, {"pos", "b", "table"}]

      result = DefaultMultigoalMethod.find_unachieved_goal(state, goals)
      assert result == nil
    end

    test "returns first unachieved goal" do
      state = AriaState.new()
      state = AriaState.set_fact(state, "pos", "a", "table")

      goals = [{"pos", "a", "table"}, {"pos", "b", "c"}, {"pos", "c", "table"}]

      result = DefaultMultigoalMethod.find_unachieved_goal(state, goals)
      assert result == {"pos", "b", "c"}
    end

    test "returns first goal when no goals are achieved" do
      state = AriaState.new()

      goals = [{"pos", "a", "b"}, {"pos", "b", "c"}]

      result = DefaultMultigoalMethod.find_unachieved_goal(state, goals)
      assert result == {"pos", "a", "b"}
    end

    test "handles empty goals list" do
      state = AriaState.new()
      goals = []

      result = DefaultMultigoalMethod.find_unachieved_goal(state, goals)
      assert result == nil
    end
  end

  describe "all_goals_achieved?/2" do
    test "returns true when all goals are achieved" do
      state = AriaState.new()
      state = AriaState.set_fact(state, "pos", "a", "table")
      state = AriaState.set_fact(state, "pos", "b", "table")
      state = AriaState.set_fact(state, "clear", "a", true)

      multigoal = %{goals: [{"pos", "a", "table"}, {"pos", "b", "table"}, {"clear", "a", true}]}

      result = DefaultMultigoalMethod.all_goals_achieved?(state, multigoal)
      assert result == true
    end

    test "returns false when some goals are unachieved" do
      state = AriaState.new()
      state = AriaState.set_fact(state, "pos", "a", "table")

      multigoal = %{goals: [{"pos", "a", "table"}, {"pos", "b", "table"}]}

      result = DefaultMultigoalMethod.all_goals_achieved?(state, multigoal)
      assert result == false
    end

    test "returns false when no goals are achieved" do
      state = AriaState.new()

      multigoal = %{goals: [{"pos", "a", "b"}, {"pos", "b", "c"}]}

      result = DefaultMultigoalMethod.all_goals_achieved?(state, multigoal)
      assert result == false
    end

    test "returns true for empty goals list" do
      state = AriaState.new()
      multigoal = %{goals: []}

      result = DefaultMultigoalMethod.all_goals_achieved?(state, multigoal)
      assert result == true
    end
  end

  describe "get_unachieved_goals/2" do
    test "returns empty list when all goals are achieved" do
      state = AriaState.new()
      state = AriaState.set_fact(state, "pos", "a", "table")
      state = AriaState.set_fact(state, "pos", "b", "table")

      multigoal = %{goals: [{"pos", "a", "table"}, {"pos", "b", "table"}]}

      result = DefaultMultigoalMethod.get_unachieved_goals(state, multigoal)
      assert result == []
    end

    test "returns all goals when none are achieved" do
      state = AriaState.new()

      multigoal = %{goals: [{"pos", "a", "b"}, {"pos", "b", "c"}]}

      result = DefaultMultigoalMethod.get_unachieved_goals(state, multigoal)
      assert result == [{"pos", "a", "b"}, {"pos", "b", "c"}]
    end

    test "returns only unachieved goals when some are achieved" do
      state = AriaState.new()
      state = AriaState.set_fact(state, "pos", "a", "table")
      state = AriaState.set_fact(state, "clear", "b", true)

      multigoal = %{goals: [{"pos", "a", "table"}, {"pos", "b", "c"}, {"clear", "b", true}, {"pos", "c", "table"}]}

      result = DefaultMultigoalMethod.get_unachieved_goals(state, multigoal)
      assert result == [{"pos", "b", "c"}, {"pos", "c", "table"}]
    end

    test "handles empty goals list" do
      state = AriaState.new()
      multigoal = %{goals: []}

      result = DefaultMultigoalMethod.get_unachieved_goals(state, multigoal)
      assert result == []
    end
  end

  describe "register_with_domain/1" do
    test "registers default multigoal method with domain" do
      domain = %{multigoal_methods: %{}}

      # Mock the AriaHybridPlanner.add_multigoal_method_to_domain function
      # In a real test, we'd need to ensure this function exists and works correctly
      result = DefaultMultigoalMethod.register_with_domain(domain)

      # This test would need to be updated based on the actual implementation
      # of AriaHybridPlanner.add_multigoal_method_to_domain
      assert is_map(result)
    end
  end

  describe "integration scenarios" do
    test "IPyHOP pattern: recursive multigoal processing" do
      # Test the IPyHOP recursive pattern where we work on one goal then continue with multigoal
      state = AriaState.new()
      
      multigoal = %{goals: [{"pos", "a", "b"}, {"pos", "b", "c"}, {"pos", "c", "table"}]}

      # First call should return first unachieved goal
      result1 = DefaultMultigoalMethod.default_multigoal_method(state, multigoal)
      assert result1 == [{"pos", "a", "b"}, multigoal]

      # Simulate achieving the first goal
      state = AriaState.set_fact(state, "pos", "a", "b")

      # Second call should return next unachieved goal
      result2 = DefaultMultigoalMethod.default_multigoal_method(state, multigoal)
      assert result2 == [{"pos", "b", "c"}, multigoal]

      # Simulate achieving the second goal
      state = AriaState.set_fact(state, "pos", "b", "c")

      # Third call should return last unachieved goal
      result3 = DefaultMultigoalMethod.default_multigoal_method(state, multigoal)
      assert result3 == [{"pos", "c", "table"}, multigoal]

      # Simulate achieving the last goal
      state = AriaState.set_fact(state, "pos", "c", "table")

      # Final call should return empty list (completion)
      result4 = DefaultMultigoalMethod.default_multigoal_method(state, multigoal)
      assert result4 == []
    end

    test "blocks world scenario from docstring" do
      # Test the exact scenario from the module docstring
      state = AriaState.new()
      state = AriaState.set_fact(state, "pos", "a", "table")
      
      multigoal = %{goals: [{"pos", "a", "b"}, {"pos", "b", "table"}]}
      
      result = DefaultMultigoalMethod.default_multigoal_method(state, multigoal)
      assert result == [{"pos", "a", "b"}, multigoal]
    end

    test "complex multigoal with mixed achievement states" do
      state = AriaState.new()
      # Set up a complex state
      state = AriaState.set_fact(state, "pos", "a", "table")
      state = AriaState.set_fact(state, "clear", "a", true)
      state = AriaState.set_fact(state, "pos", "d", "table")

      multigoal = %{
        goals: [
          {"pos", "a", "table"},    # achieved
          {"clear", "a", true},     # achieved
          {"pos", "b", "c"},        # not achieved - should be returned
          {"pos", "c", "table"},    # not achieved
          {"pos", "d", "table"},    # achieved
          {"clear", "e", true}      # not achieved
        ]
      }

      result = DefaultMultigoalMethod.default_multigoal_method(state, multigoal)
      assert result == [{"pos", "b", "c"}, multigoal]

      # Verify helper functions work correctly with this scenario
      assert DefaultMultigoalMethod.all_goals_achieved?(state, multigoal) == false
      
      unachieved = DefaultMultigoalMethod.get_unachieved_goals(state, multigoal)
      assert unachieved == [{"pos", "b", "c"}, {"pos", "c", "table"}, {"clear", "e", true}]
      
      first_unachieved = DefaultMultigoalMethod.find_unachieved_goal(state, multigoal.goals)
      assert first_unachieved == {"pos", "b", "c"}
    end
  end
end
