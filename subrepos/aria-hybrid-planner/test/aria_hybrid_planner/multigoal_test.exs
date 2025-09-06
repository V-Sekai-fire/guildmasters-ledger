defmodule AriaEngineCore.MultigoalTest do
  use ExUnit.Case, async: true

  alias AriaEngineCore.Multigoal
  alias AriaState

  describe "new/0" do
    test "creates an empty multigoal" do
      multigoal = Multigoal.new()
      assert multigoal.goals == []
    end
  end

  describe "new/1" do
    test "creates a multigoal from a list of goals" do
      goals = [{"location", "player", "room1"}, {"has", "player", "key"}]
      multigoal = Multigoal.new(goals)
      assert multigoal.goals == goals
    end
  end

  describe "from_state/1" do
    test "creates a multigoal from a state" do
      state = AriaState.new()
      state = AriaState.set_fact(state, "location", "player", "room1")
      state = AriaState.set_fact(state, "has", "player", "key")

      multigoal = Multigoal.from_state(state)
      goals = Multigoal.to_list(multigoal)
      assert length(goals) == 2
      assert {"location", "player", "room1"} in goals
      assert {"has", "player", "key"} in goals
    end
  end

  describe "add_goal/4" do
    test "adds a goal to the multigoal" do
      multigoal = Multigoal.new()
      multigoal = Multigoal.add_goal(multigoal, "location", "player", "room1")

      assert Multigoal.size(multigoal) == 1
      assert Multigoal.to_list(multigoal) == [{"location", "player", "room1"}]
    end
  end

  describe "add_goals/2" do
    test "adds multiple goals to the multigoal" do
      multigoal = Multigoal.new()
      goals = [{"location", "player", "room1"}, {"has", "player", "key"}]
      multigoal = Multigoal.add_goals(multigoal, goals)

      assert Multigoal.size(multigoal) == 2
      assert Multigoal.to_list(multigoal) == goals
    end
  end

  describe "remove_goal/4" do
    test "removes a specific goal from the multigoal" do
      multigoal = Multigoal.new()
      multigoal = Multigoal.add_goal(multigoal, "location", "player", "room1")
      multigoal = Multigoal.add_goal(multigoal, "has", "player", "key")

      multigoal = Multigoal.remove_goal(multigoal, "location", "player", "room1")

      assert Multigoal.size(multigoal) == 1
      assert Multigoal.to_list(multigoal) == [{"has", "player", "key"}]
    end
  end

  describe "satisfied?/2" do
    test "returns true for empty multigoal" do
      state = AriaState.new()
      multigoal = Multigoal.new()

      assert Multigoal.satisfied?(multigoal, state)
    end

    test "returns false when some goals are not satisfied" do
      state = AriaState.new()
      state = AriaState.set_fact(state, "location", "player", "room1")

      multigoal = Multigoal.new()
      multigoal = Multigoal.add_goal(multigoal, "location", "player", "room1")
      multigoal = Multigoal.add_goal(multigoal, "has", "player", "key")

      refute Multigoal.satisfied?(multigoal, state)
    end
  end

  describe "unsatisfied_goals/2" do
    test "returns goals that are not satisfied" do
      state = AriaState.new()
      state = AriaState.set_fact(state, "location", "player", "room1")

      multigoal = Multigoal.new()
      multigoal = Multigoal.add_goal(multigoal, "location", "player", "room1")
      multigoal = Multigoal.add_goal(multigoal, "has", "player", "key")

      unsatisfied = Multigoal.unsatisfied_goals(multigoal, state)
      assert is_list(unsatisfied)
      assert {"has", "player", "key"} in unsatisfied
    end
  end



  describe "empty?/1" do
    test "returns true for empty multigoal" do
      multigoal = Multigoal.new()
      assert Multigoal.empty?(multigoal)
    end

    test "returns false for non-empty multigoal" do
      multigoal = Multigoal.new()
      multigoal = Multigoal.add_goal(multigoal, "location", "player", "room1")
      refute Multigoal.empty?(multigoal)
    end
  end

  describe "size/1" do
    test "returns the number of goals" do
      multigoal = Multigoal.new()
      assert Multigoal.size(multigoal) == 0

      multigoal = Multigoal.add_goal(multigoal, "location", "player", "room1")
      assert Multigoal.size(multigoal) == 1
    end
  end

  describe "to_state/1" do
    test "converts multigoal to state" do
      multigoal = Multigoal.new()
      multigoal = Multigoal.add_goal(multigoal, "location", "player", "room1")

      state = Multigoal.to_state(multigoal)
      assert AriaState.get_fact(state, "location", "player") == {:ok, "room1"}
    end
  end

  describe "to_list/1" do
    test "returns goals as a list" do
      goals = [{"location", "player", "room1"}]
      multigoal = Multigoal.new(goals)

      assert Multigoal.to_list(multigoal) == goals
    end
  end

  describe "merge/2" do
    test "merges two multigoals" do
      multigoal1 = Multigoal.new()
      multigoal1 = Multigoal.add_goal(multigoal1, "location", "player", "room1")

      multigoal2 = Multigoal.new()
      multigoal2 = Multigoal.add_goal(multigoal2, "has", "player", "key")

      merged = Multigoal.merge(multigoal1, multigoal2)
      assert Multigoal.size(merged) == 2
    end
  end

  describe "copy/1" do
    test "creates a copy of the multigoal" do
      multigoal = Multigoal.new()
      multigoal = Multigoal.add_goal(multigoal, "location", "player", "room1")

      copy = Multigoal.copy(multigoal)
      assert Multigoal.to_list(copy) == Multigoal.to_list(multigoal)
      # The copy function may return the same struct, so we just verify it works
      assert is_struct(copy)
    end
  end

  describe "filter/2" do
    test "filters goals based on predicate" do
      multigoal = Multigoal.new()
      multigoal = Multigoal.add_goal(multigoal, "location", "player", "room1")
      multigoal = Multigoal.add_goal(multigoal, "has", "player", "key")

      filtered = Multigoal.filter(multigoal, fn {pred, _, _} -> pred == "location" end)
      assert Multigoal.size(filtered) == 1
      assert Multigoal.to_list(filtered) == [{"location", "player", "room1"}]
    end
  end

  describe "map/2" do
    test "maps over goals" do
      multigoal = Multigoal.new()
      multigoal = Multigoal.add_goal(multigoal, "location", "player", "room1")

      mapped = Multigoal.map(multigoal, fn {pred, subj, fact} ->
        {pred, subj, String.upcase(fact)}
      end)

      assert Multigoal.to_list(mapped) == [{"location", "player", "ROOM1"}]
    end
  end

  describe "split_multigoal/2" do
    test "splits valid goals" do
      goals = [["on", "a", "b"], ["on", "b", "table"]]
      result = Multigoal.split_multigoal(AriaState.new(), goals)
      assert result == goals
    end

    test "filters out invalid goals" do
      goals = [["on", "a", "b"], "invalid", []]
      result = Multigoal.split_multigoal(AriaState.new(), goals)
      assert result == [["on", "a", "b"]]
    end

    test "returns empty list for empty goals" do
      result = Multigoal.split_multigoal(AriaState.new(), [])
      assert result == []
    end

    test "returns false for invalid input" do
      result = Multigoal.split_multigoal(AriaState.new(), "invalid")
      assert result == false
    end
  end

  describe "valid_goal?/1" do
    test "returns true for valid goals" do
      assert Multigoal.valid_goal?(["on", "a", "b"])
      assert Multigoal.valid_goal?(["location", "player"])
    end

    test "returns false for invalid goals" do
      refute Multigoal.valid_goal?([])
      refute Multigoal.valid_goal?("invalid")
      refute Multigoal.valid_goal?(nil)
    end
  end
end
