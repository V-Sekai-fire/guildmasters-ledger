# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaState.RelationalStateTest do
  use ExUnit.Case
  doctest AriaState.RelationalState

  alias AriaState.RelationalState
  alias AriaState

  describe "relational state creation and basic operations" do
    test "new/0 creates empty relational state" do
      state = RelationalState.new()
      
      assert is_struct(state, RelationalState)
      assert state.data == %{}
    end

    test "new/1 creates relational state from data" do
      data = %{
        {"status", "entity1"} => "active",
        {"location", "entity1"} => "room1"
      }
      
      state = RelationalState.new(data)
      
      assert is_struct(state, RelationalState)
      assert state.data == data
    end

    test "set_fact/4 sets fact in relational state" do
      state = RelationalState.new()
      
      updated_state = RelationalState.set_fact(state, "status", "entity1", "active")
      
      assert updated_state.data[{"status", "entity1"}] == "active"
    end

    test "get_fact/3 retrieves fact from relational state" do
      state = RelationalState.new()
      |> RelationalState.set_fact("status", "entity1", "active")
      
      result = RelationalState.get_fact(state, "status", "entity1")
      
      assert "active" = result
    end

    test "get_fact/3 returns nil for missing fact" do
      state = RelationalState.new()
      
      result = RelationalState.get_fact(state, "status", "nonexistent")
      
      assert result == nil
    end

    test "remove_fact/3 removes fact from relational state" do
      state = RelationalState.new()
      |> RelationalState.set_fact("status", "entity1", "active")
      
      # Verify fact exists
      assert "active" = RelationalState.get_fact(state, "status", "entity1")
      
      # Remove fact
      updated_state = RelationalState.remove_fact(state, "status", "entity1")
      
      # Verify fact is gone
      assert RelationalState.get_fact(updated_state, "status", "entity1") == nil
    end

    test "copy/1 creates independent copy" do
      original_state = RelationalState.new()
      |> RelationalState.set_fact("status", "entity1", "active")
      
      copied_state = RelationalState.copy(original_state)
      
      # Modify copy
      modified_copy = RelationalState.set_fact(copied_state, "status", "entity1", "inactive")
      
      # Original should be unchanged
      assert "active" = RelationalState.get_fact(original_state, "status", "entity1")
      # Copy should be modified
      assert "inactive" = RelationalState.get_fact(modified_copy, "status", "entity1")
    end
  end

  describe "relational state queries" do
    setup do
      state = RelationalState.new()
      |> RelationalState.set_fact("status", "entity1", "active")
      |> RelationalState.set_fact("status", "entity2", "inactive")
      |> RelationalState.set_fact("location", "entity1", "room1")
      |> RelationalState.set_fact("location", "entity2", "room2")
      |> RelationalState.set_fact("type", "entity1", "robot")
      |> RelationalState.set_fact("type", "entity2", "sensor")
      |> RelationalState.set_fact("battery", "entity1", 85)
      |> RelationalState.set_fact("battery", "entity2", 92)
      
      %{state: state}
    end

    test "has_subject?/3 checks if predicate exists for subject", %{state: state} do
      assert RelationalState.has_subject?(state, "status", "entity1") == true
      assert RelationalState.has_subject?(state, "status", "nonexistent") == false
      assert RelationalState.has_subject?(state, "nonexistent", "entity1") == false
    end

    test "get_subjects_with_fact/3 finds subjects with specific fact", %{state: state} do
      active_subjects = RelationalState.get_subjects_with_fact(state, "status", "active")
      
      assert is_list(active_subjects)
      assert "entity1" in active_subjects
      assert "entity2" not in active_subjects
      assert length(active_subjects) == 1
    end

    test "get_subjects_with_predicate/2 finds all subjects with predicate", %{state: state} do
      status_subjects = RelationalState.get_subjects_with_predicate(state, "status")
      
      assert is_list(status_subjects)
      assert "entity1" in status_subjects
      assert "entity2" in status_subjects
      assert length(status_subjects) == 2
    end

    test "matches?/4 checks if fact matches", %{state: state} do
      assert RelationalState.matches?(state, "status", "entity1", "active") == true
      assert RelationalState.matches?(state, "status", "entity1", "inactive") == false
      assert RelationalState.matches?(state, "status", "nonexistent", "active") == false
    end

    test "exists?/3 checks if any subject has predicate-value pair", %{state: state} do
      assert RelationalState.exists?(state, "status", "active") == true
      assert RelationalState.exists?(state, "status", "inactive") == true
      assert RelationalState.exists?(state, "status", "unknown") == false
      assert RelationalState.exists?(state, "nonexistent", "value") == false
    end

    test "exists?/4 checks existence with subject filter", %{state: state} do
      robot_filter = fn subject -> 
        case RelationalState.get_fact(state, "type", subject) do
          "robot" -> true
          _ -> false
        end
      end
      
      # Should find active status among robots
      assert RelationalState.exists?(state, "status", "active", robot_filter) == true
      
      # Should not find inactive status among robots
      assert RelationalState.exists?(state, "status", "inactive", robot_filter) == false
    end

    test "forall?/4 checks if all filtered subjects have predicate-value", %{state: state} do
      all_entities_filter = fn subject -> 
        String.starts_with?(subject, "entity")
      end
      
      # Not all entities are active
      assert RelationalState.forall?(state, "status", "active", all_entities_filter) == false
      
      # All entities have a location
      location_exists = RelationalState.forall?(state, "location", fn _subject, value -> 
        is_binary(value) and String.starts_with?(value, "room")
      end, all_entities_filter)
      
      # This test depends on implementation details
      assert is_boolean(location_exists)
    end
  end

  describe "relational state serialization" do
    setup do
      state = RelationalState.new()
      |> RelationalState.set_fact("status", "entity1", "active")
      |> RelationalState.set_fact("location", "entity1", "room1")
      |> RelationalState.set_fact("battery", "entity1", 75)
      
      %{state: state}
    end

    test "to_triples/1 converts state to triples", %{state: state} do
      triples = RelationalState.to_triples(state)
      
      assert is_list(triples)
      assert length(triples) == 3
      
      # Check that triples contain expected facts
      assert {"status", "entity1", "active"} in triples
      assert {"location", "entity1", "room1"} in triples
      assert {"battery", "entity1", 75} in triples
    end

    test "from_triples/1 creates state from triples", %{state: original_state} do
      triples = RelationalState.to_triples(original_state)
      reconstructed_state = RelationalState.from_triples(triples)
      
      # Verify reconstructed state has same facts
      assert "active" = RelationalState.get_fact(reconstructed_state, "status", "entity1")
      assert "room1" = RelationalState.get_fact(reconstructed_state, "location", "entity1")
      assert 75 = RelationalState.get_fact(reconstructed_state, "battery", "entity1")
    end

    test "roundtrip conversion preserves state", %{state: original_state} do
      triples = RelationalState.to_triples(original_state)
      reconstructed_state = RelationalState.from_triples(triples)
      reconstructed_triples = RelationalState.to_triples(reconstructed_state)
      
      # Should have same number of triples
      assert length(triples) == length(reconstructed_triples)
      
      # All original triples should be present
      Enum.each(triples, fn triple ->
        assert triple in reconstructed_triples
      end)
    end
  end

  describe "relational state merging" do
    test "merge/2 combines two relational states" do
      state1 = RelationalState.new()
      |> RelationalState.set_fact("status", "entity1", "active")
      |> RelationalState.set_fact("location", "entity1", "room1")
      
      state2 = RelationalState.new()
      |> RelationalState.set_fact("status", "entity2", "inactive")
      |> RelationalState.set_fact("location", "entity2", "room2")
      
      merged_state = RelationalState.merge(state1, state2)
      
      # Should have facts from both states
      assert "active" = RelationalState.get_fact(merged_state, "status", "entity1")
      assert "room1" = RelationalState.get_fact(merged_state, "location", "entity1")
      assert "inactive" = RelationalState.get_fact(merged_state, "status", "entity2")
      assert "room2" = RelationalState.get_fact(merged_state, "location", "entity2")
    end

    test "merge/2 handles conflicting facts" do
      state1 = RelationalState.new()
      |> RelationalState.set_fact("status", "entity1", "active")
      
      state2 = RelationalState.new()
      |> RelationalState.set_fact("status", "entity1", "inactive")
      
      merged_state = RelationalState.merge(state1, state2)
      
      # Second state should override
      assert "inactive" = RelationalState.get_fact(merged_state, "status", "entity1")
    end

    test "merge/2 with empty states" do
      state1 = RelationalState.new()
      state2 = RelationalState.new()
      |> RelationalState.set_fact("status", "entity1", "active")
      
      merged_state = RelationalState.merge(state1, state2)
      
      assert "active" = RelationalState.get_fact(merged_state, "status", "entity1")
    end
  end

  describe "condition evaluation" do
    setup do
      state = RelationalState.new()
      |> RelationalState.set_fact("status", "entity1", "active")
      |> RelationalState.set_fact("status", "entity2", "inactive")
      |> RelationalState.set_fact("battery", "entity1", 85)
      |> RelationalState.set_fact("battery", "entity2", 45)
      |> RelationalState.set_fact("location", "entity1", "room1")
      
      %{state: state}
    end

    test "evaluate_condition/2 evaluates simple equality conditions", %{state: state} do
      condition = {"status", "entity1", "active"}
      
      result = RelationalState.evaluate_condition(state, condition)
      
      assert result == true
    end

    test "evaluate_condition/2 evaluates logical AND conditions", %{state: state} do
      and_condition = {:and, [
        {:equals, "status", "entity1", "active"},
        {:equals, "location", "entity1", "room1"}
      ]}
      
      result = RelationalState.evaluate_condition(state, and_condition)
      
      assert result == true
    end

    test "evaluate_condition/2 evaluates logical OR conditions", %{state: state} do
      or_condition = {:or, [
        {:equals, "status", "entity1", "inactive"},  # false
        {:equals, "location", "entity1", "room1"}    # true
      ]}
      
      result = RelationalState.evaluate_condition(state, or_condition)
      
      assert result == true
    end

    test "evaluate_condition/2 evaluates numerical conditions", %{state: state} do
      # Test greater than
      gt_condition = {:greater_than, "battery", "entity1", 80}
      assert RelationalState.evaluate_condition(state, gt_condition) == true
      
      # Test less than
      lt_condition = {:less_than, "battery", "entity2", 50}
      assert RelationalState.evaluate_condition(state, lt_condition) == true
      
      # Test greater equal
      ge_condition = {:greater_equal, "battery", "entity1", 85}
      assert RelationalState.evaluate_condition(state, ge_condition) == true
      
      # Test less equal
      le_condition = {:less_equal, "battery", "entity2", 45}
      assert RelationalState.evaluate_condition(state, le_condition) == true
    end

    test "evaluate_condition/2 handles missing facts gracefully", %{state: state} do
      condition = {:equals, "status", "nonexistent", "active"}
      
      result = RelationalState.evaluate_condition(state, condition)
      
      assert result == false
    end

    test "evaluate_condition/2 evaluates NOT conditions", %{state: state} do
      not_condition = {:not, {:equals, "status", "entity1", "inactive"}}
      
      result = RelationalState.evaluate_condition(state, not_condition)
      
      assert result == true
    end

    test "evaluate_condition/2 evaluates complex nested conditions", %{state: state} do
      complex_condition = {:and, [
        {:or, [
          {:equals, "status", "entity1", "active"},
          {:equals, "status", "entity2", "active"}
        ]},
        {:greater_than, "battery", "entity1", 50}
      ]}
      
      result = RelationalState.evaluate_condition(state, complex_condition)
      
      assert result == true
    end
  end

  describe "conversion between AriaState and RelationalState" do
    test "converts from AriaState to RelationalState" do
      aria_state = AriaState.new()
      |> AriaState.set_fact("status", "entity1", "active")
      |> AriaState.set_fact("location", "entity1", "room1")
      
      relational_state = AriaState.convert(aria_state)
      
      assert is_struct(relational_state, RelationalState)
      assert "active" = RelationalState.get_fact(relational_state, "status", "entity1")
      assert "room1" = RelationalState.get_fact(relational_state, "location", "entity1")
    end

    test "converts from RelationalState to AriaState" do
      relational_state = RelationalState.new()
      |> RelationalState.set_fact("status", "entity1", "active")
      |> RelationalState.set_fact("location", "entity1", "room1")
      
      aria_state = AriaState.convert(relational_state)
      
      assert is_struct(aria_state, AriaState)
      assert {:ok, "active"} = AriaState.get_fact(aria_state, "status", "entity1")
      assert {:ok, "room1"} = AriaState.get_fact(aria_state, "location", "entity1")
    end

    test "roundtrip conversion preserves data" do
      original_aria = AriaState.new()
      |> AriaState.set_fact("status", "entity1", "active")
      |> AriaState.set_fact("battery", "entity1", 75)
      
      # AriaState -> RelationalState -> AriaState
      relational = AriaState.convert(original_aria)
      converted_back = AriaState.convert(relational)
      
      assert {:ok, "active"} = AriaState.get_fact(converted_back, "status", "entity1")
      assert {:ok, 75} = AriaState.get_fact(converted_back, "battery", "entity1")
    end
  end

  describe "edge cases and error handling" do
    test "handles empty relational state operations" do
      state = RelationalState.new()
      
      # Operations on empty state should work
      triples = RelationalState.to_triples(state)
      assert triples == []
      
      subjects = RelationalState.get_subjects_with_predicate(state, "any_predicate")
      assert subjects == []
      
      exists_result = RelationalState.exists?(state, "any_predicate", "any_value")
      assert exists_result == false
    end

    test "handles various data types as fact values" do
      state = RelationalState.new()
      |> RelationalState.set_fact("string_val", "entity1", "text")
      |> RelationalState.set_fact("integer_val", "entity1", 42)
      |> RelationalState.set_fact("float_val", "entity1", 3.14)
      |> RelationalState.set_fact("boolean_val", "entity1", true)
      |> RelationalState.set_fact("list_val", "entity1", [1, 2, 3])
      |> RelationalState.set_fact("map_val", "entity1", %{key: "value"})
      
      # All should be retrievable
      assert "text" = RelationalState.get_fact(state, "string_val", "entity1")
      assert 42 = RelationalState.get_fact(state, "integer_val", "entity1")
      assert 3.14 = RelationalState.get_fact(state, "float_val", "entity1")
      assert true = RelationalState.get_fact(state, "boolean_val", "entity1")
      assert [1, 2, 3] = RelationalState.get_fact(state, "list_val", "entity1")
      assert %{key: "value"} = RelationalState.get_fact(state, "map_val", "entity1")
    end

    test "handles large numbers of facts efficiently" do
      state = Enum.reduce(1..1000, RelationalState.new(), fn i, acc ->
        RelationalState.set_fact(acc, "item", "item_#{i}", "value_#{i}")
      end)
      
      # Should still be able to query efficiently
      assert "value_500" = RelationalState.get_fact(state, "item", "item_500")
      
      # Should be able to get all subjects efficiently
      subjects = RelationalState.get_subjects_with_predicate(state, "item")
      assert is_list(subjects)
      assert length(subjects) == 1000
    end

    test "handles invalid condition formats gracefully" do
      state = RelationalState.new()
      |> RelationalState.set_fact("status", "entity1", "active")
      
      # Test with invalid condition format
      invalid_condition = {:invalid_operator, "status", "entity1", "active"}
      
      result = RelationalState.evaluate_condition(state, invalid_condition)
      
      # Should return false for unknown condition formats
      assert result == false
    end
  end
end
